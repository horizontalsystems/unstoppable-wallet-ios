import Foundation
import HsToolKit
import MarketKit
import RxSwift

/// Spam manager with fully synchronous processing in a single queue.
///
/// Initialization order:
/// 1. When adapters are ready (adaptersReadyObservable):
///    - For each source sequentially in queue:
///      a) Load outputCache from adapter's outgoing transactions
///      b) Load and process unscanned transactions (from oldest to newest)
///      c) Subscribe to new transactions
/// 2. After initialization, the queue processes:
///    - New transactions from transactionsObservable
///    - Synchronous isSpam() checks
///
/// External callers (converters) wait for initialization before spam checks.
final class SpamManagerNew {
    private let queue = DispatchQueue(label: "\(AppConfig.label).spam-manager-new", qos: .userInitiated)

    private let disposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private let storage: ScannedTransactionStorage
    private let accountManager: AccountManager
    private let filterChain: SpamFilterChain
    private let scoreEvaluator: SpamScoreEvaluator
    private let outputCache: OutputTransactionCache
    private let spamTransactionInfoFactory: SpamTransactionInfoFactory
    private let logger: Logger?

    private var transactionAdapterManager: TransactionAdapterManager?

    // MARK: - Initialization State

    /// Tracks which blockchains have been initialized
    private var initializedBlockchains = Set<String>()

    /// Condition variable for waiting on initialization
    private let initCondition = NSCondition()

    /// Timeout for waiting on initialization (seconds)
    private let initTimeout: TimeInterval = 30

    // MARK: - Init

    init(
        storage: ScannedTransactionStorage,
        accountManager: AccountManager,
        filterChain: SpamFilterChain,
        scoreEvaluator: SpamScoreEvaluator,
        outputCache: OutputTransactionCache,
        spamTransactionInfoFactory: SpamTransactionInfoFactory,
        logger: Logger? = nil
    ) {
        self.storage = storage
        self.accountManager = accountManager
        self.filterChain = filterChain
        self.scoreEvaluator = scoreEvaluator
        self.outputCache = outputCache
        self.spamTransactionInfoFactory = spamTransactionInfoFactory
        self.logger = logger
    }

    // MARK: - Setup

    func set(transactionAdapterManager: TransactionAdapterManager) {
        self.transactionAdapterManager = transactionAdapterManager

        subscribe(disposeBag, transactionAdapterManager.adaptersReadyObservable) { [weak self] in
            self?.handleAdaptersReady()
        }
    }

    private func handleAdaptersReady() {
        adaptersDisposeBag = DisposeBag()

        guard let transactionAdapterManager else {
            logger?.log(level: .error, message: "SMNew: TransactionAdapterManager not set!")
            return
        }

        // Reset initialization state for new adapter set
        initCondition.lock()
        initializedBlockchains.removeAll()
        initCondition.unlock()

        guard !transactionAdapterManager.adapterMap.isEmpty else {
            logger?.log(level: .debug, message: "SMNew: adapters ready but empty, skipping")
            return
        }

        logger?.log(level: .debug, message: "SMNew: adapters ready, count=\(transactionAdapterManager.adapterMap.count)")

        // Everything happens sequentially in queue
        queue.async { [weak self] in
            self?.initializeAllAdapters()
        }
    }

    /// Sequential initialization of all adapters in queue
    private func initializeAllAdapters() {
        guard let transactionAdapterManager else { return }

        for (source, adapter) in transactionAdapterManager.adapterMap {
            initializeAdapter(source: source, adapter: adapter)
        }

        // After initialization subscribe to updates
        subscribeToAdapters()
    }

    /// Single adapter initialization:
    /// 1. Load outputCache
    /// 2. Process unscanned transactions
    /// 3. Mark blockchain as initialized
    private func initializeAdapter(source: TransactionSource, adapter: ITransactionsAdapter) {
        let blockchainType = source.blockchainType

        logger?.log(level: .debug, message: "SMNew: initializing \(blockchainType.uid)")

        // Step 1: Load outgoing transactions cache
        outputCache.loadCache(for: blockchainType, adapter: adapter)

        // Step 2: Process unscanned transactions
        processUnscannedTransactions(source: source, adapter: adapter)

        // Step 3: Mark as initialized and signal waiters
        markInitialized(blockchainType: blockchainType)

        logger?.log(level: .debug, message: "SMNew: initialized \(blockchainType.uid)")
    }

    /// Mark blockchain as initialized and wake up waiting threads
    private func markInitialized(blockchainType: BlockchainType) {
        initCondition.lock()
        initializedBlockchains.insert(blockchainType.uid)
        initCondition.broadcast()
        initCondition.unlock()
    }

    /// Check if blockchain is initialized
    private func isInitialized(blockchainType: BlockchainType) -> Bool {
        initCondition.lock()
        defer { initCondition.unlock() }
        return initializedBlockchains.contains(blockchainType.uid)
    }

    /// Wait for blockchain initialization with timeout
    /// Returns true if initialized, false if timeout
    private func waitForInitialization(blockchainType: BlockchainType) -> Bool {
        initCondition.lock()
        defer { initCondition.unlock() }

        let deadline = Date().addingTimeInterval(initTimeout)

        while !initializedBlockchains.contains(blockchainType.uid) {
            if !initCondition.wait(until: deadline) {
                // Timeout reached
                logger?.log(level: .warning, message: "SMNew: initialization timeout for \(blockchainType.uid)")
                return false
            }
        }

        return true
    }

    /// Subscribe to new transactions (after initialization)
    private func subscribeToAdapters() {
        guard let transactionAdapterManager else { return }

        for (source, adapter) in transactionAdapterManager.adapterMap {
            subscribe(adaptersDisposeBag, adapter.transactionsObservable(token: nil, filter: .all, address: nil)) { [weak self] records in
                self?.logger?.log(level: .debug, message: "SMNew: observable -> \(records.count) records for \(source.blockchainType.uid)")
                self?.enqueueSync(source: source)
            }
        }

        logger?.log(level: .debug, message: "SMNew: subscribed to all adapters")
    }

    // MARK: - Sync

    private func enqueueSync(source: TransactionSource) {
        queue.async { [weak self] in
            self?.sync(source: source)
        }
    }

    /// Synchronization: load and process new transactions
    private func sync(source: TransactionSource) {
        guard let adapter = transactionAdapterManager?.adapter(for: source) else {
            logger?.log(level: .error, message: "SMNew: no adapter for \(source.blockchainType.uid)")
            return
        }

        processUnscannedTransactions(source: source, adapter: adapter)
    }

    /// Loads and processes transactions that haven't been scanned yet
    private func processUnscannedTransactions(source: TransactionSource, adapter: ITransactionsAdapter) {
        guard let accountUid = accountManager.activeAccount?.id else {
            logger?.log(level: .error, message: "SMNew: no active account")
            return
        }

        let blockchainTypeUid = source.blockchainType.uid
        let spamScanState = try? storage.find(blockchainTypeUid: blockchainTypeUid, accountUid: accountUid)

        // Synchronously load transactions
        let transactions = loadTransactionsSync(
            adapter: adapter,
            afterPaginationData: spamScanState?.lastPaginationData
        )

        guard !transactions.isEmpty else {
            logger?.log(level: .debug, message: "SMNew: no new transactions for \(blockchainTypeUid)")
            return
        }

        logger?.log(level: .debug, message: "SMNew: processing \(transactions.count) transactions for \(blockchainTypeUid)")

        // Process from oldest to newest
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
        let lastPaginationData = handleTransactions(transactions: sortedTransactions, source: source)

        // Save scan state
        if let lastPaginationData {
            let newState = SpamScanState(
                blockchainTypeUid: blockchainTypeUid,
                accountUid: accountUid,
                lastPaginationData: lastPaginationData
            )
            try? storage.save(spamScanState: newState)
        }
    }

    /// Synchronous transaction loading via semaphore
    private func loadTransactionsSync(adapter: ITransactionsAdapter, afterPaginationData: String?) -> [TransactionRecord] {
        let semaphore = DispatchSemaphore(value: 0)
        var transactions = [TransactionRecord]()

        adapter
            .allTransactionsAfter(paginationData: afterPaginationData)
            .subscribe(
                onSuccess: { result in
                    transactions = result
                    semaphore.signal()
                },
                onError: { [weak self] error in
                    self?.logger?.log(level: .error, message: "SMNew: load error: \(error)")
                    semaphore.signal()
                }
            )
            .disposed(by: disposeBag)

        semaphore.wait()
        return transactions
    }

    // MARK: - Transaction Handling

    /// Processes transactions: checks for spam, adds to cache
    /// Returns paginationData of the last processed transaction
    private func handleTransactions(transactions: [TransactionRecord], source: TransactionSource) -> String? {
        var lastPaginationData: String?

        for record in transactions {
            guard let hashData = record.transactionHash.hs.hexData else {
                continue
            }

            // Already scanned — skip
            if let _ = try? storage.findScanned(transactionHash: hashData) {
                lastPaginationData = record.paginationRaw
                continue
            }

            // Process transaction
            processTransaction(record: record, hashData: hashData, source: source)

            lastPaginationData = record.paginationRaw
        }

        return lastPaginationData
    }

    /// Single transaction processing
    private func processTransaction(record: TransactionRecord, hashData: Data, source: TransactionSource) {
        // Check if there are outgoing events — add to cache
        if hasOutgoingEvents(record: record) {
            outputCache.add(record: record)

            // Outgoing transactions are not checked for spam, but saved as "not spam"
            let scanned = ScannedTransaction(
                transactionHash: hashData,
                blockchainTypeUid: source.blockchainType.uid,
                isSpam: false,
                spamAddress: nil
            )
            try? storage.save(scannedTransaction: scanned)

            logger?.log(level: .debug, message: "SMNew: outgoing \(record.transactionHash.prefix(8))... -> cached")
            return
        }

        // For others — check for spam
        guard let spamInfo = spamTransactionInfoFactory.spamTransactionInfo(from: record) else {
            // No events to check — save as "not spam"
            let scanned = ScannedTransaction(
                transactionHash: hashData,
                blockchainTypeUid: source.blockchainType.uid,
                isSpam: false,
                spamAddress: nil
            )
            try? storage.save(scannedTransaction: scanned)
            return
        }

        let isSpam = evaluateSpam(spamInfo: spamInfo)
        let spamAddress = isSpam ? spamInfo.events.incoming.first?.address : nil

        let scanned = ScannedTransaction(
            transactionHash: hashData,
            blockchainTypeUid: source.blockchainType.uid,
            isSpam: isSpam,
            spamAddress: spamAddress
        )
        try? storage.save(scannedTransaction: scanned)

        logger?.log(level: .debug, message: "SMNew: scanned \(record.transactionHash.prefix(8))... isSpam=\(isSpam)")
    }

    /// Checks if transaction has outgoing events
    private func hasOutgoingEvents(record: TransactionRecord) -> Bool {
        switch record {
        case is EvmOutgoingTransactionRecord,
             is TronOutgoingTransactionRecord,
             is BitcoinOutgoingTransactionRecord,
             is MoneroOutgoingTransactionRecord:
            return true

        case let record as TonTransactionRecord:
            return record.actions.contains { action in
                if case .send = action.type { return true }
                return false
            }

        case let record as StellarTransactionRecord:
            if case .sendPayment = record.type { return true }
            return false

        case let record as ExternalContractCallTransactionRecord:
            return !record.outgoingEvents.isEmpty

        case let record as TronExternalContractCallTransactionRecord:
            return !record.outgoingEvents.isEmpty

        case let record as ContractCallTransactionRecord:
            return !record.outgoingEvents.isEmpty

        default:
            return false
        }
    }

    // MARK: - Spam Evaluation

    /// Transaction spam evaluation (synchronous)
    private func evaluateSpam(spamInfo: SpamTransactionInfo) -> Bool {
        // Step 1: Filters (fast checks)
        if let filterResult = filterChain.evaluate(spamInfo) {
            switch filterResult {
            case .spam:
                logger?.log(level: .debug, message: "SMNew: filter -> spam")
                return true
            case .trusted:
                logger?.log(level: .debug, message: "SMNew: filter -> trusted")
                return false
            case .ignore:
                break
            }
        }

        // Step 2: Score evaluation (detailed check)
        let context = SpamEvaluationContext(transaction: spamInfo)
        let decision = scoreEvaluator.evaluate(context)

        switch decision {
        case .spam:
            logger?.log(level: .debug, message: "SMNew: score -> spam")
            return true
        case let .suspicious(score):
            logger?.log(level: .debug, message: "SMNew: score -> suspicious(\(score))")
            return true
        case .trusted:
            return false
        }
    }

    // MARK: - Public API

    /// Check transaction for spam.
    /// First checks cache (scannedTransactions), if not found — calculates synchronously in queue.
    func isSpam(transactionHash: Data, record: TransactionRecord) -> Bool {
        // First check cache (outside queue, as it's just a DB read)
        if let scanned = try? storage.findScanned(transactionHash: transactionHash) {
            logger?.log(level: .debug, message: "SMNew: cache hit \(transactionHash.hs.hexString.prefix(8))... isSpam=\(scanned.isSpam)")
            return scanned.isSpam
        }

        // Calculate in queue synchronously
        var result = false
        queue.sync { [weak self] in
            guard let self else { return }
            result = performCheckSpam(transactionHash: transactionHash, record: record)
        }
        return result
    }

    /// Check address for spam (using previously saved data)
    func isSpam(address: String) -> Bool {
        (try? storage.findScanned(address: address))?.isSpam ?? false
    }

    /// Check SpamTransactionInfo for spam.
    /// Called from converters during transaction conversion.
    /// Waits for blockchain initialization before checking.
    func isSpam(spamInfo: SpamTransactionInfo) -> Bool {
        guard let hashData = spamInfo.hash.hs.hexData else {
            return false
        }

        // Check DB cache first (fast path, no waiting needed)
        if let scanned = try? storage.findScanned(transactionHash: hashData) {
            return scanned.isSpam
        }

        // Wait for blockchain initialization
        let blockchainType = spamInfo.blockchainType
        if !isInitialized(blockchainType: blockchainType) {
            logger?.log(level: .debug, message: "SMNew: waiting for \(blockchainType.uid) initialization...")
            if !waitForInitialization(blockchainType: blockchainType) {
                // Timeout — return false (not spam) as safe default
                logger?.log(level: .warning, message: "SMNew: timeout waiting for \(blockchainType.uid), returning not spam")
                return false
            }
            logger?.log(level: .debug, message: "SMNew: \(blockchainType.uid) initialized, continuing check")
        }

        // Double-check cache after waiting (might have been processed during init)
        if let scanned = try? storage.findScanned(transactionHash: hashData) {
            return scanned.isSpam
        }

        // Not in cache — evaluate and save synchronously in queue
        var result = false
        queue.sync { [weak self] in
            guard let self else { return }

            // Triple-check after entering queue
            if let scanned = try? storage.findScanned(transactionHash: hashData) {
                result = scanned.isSpam
                return
            }

            let isSpam = evaluateSpam(spamInfo: spamInfo)
            let spamAddress = isSpam ? spamInfo.events.incoming.first?.address : nil

            let scanned = ScannedTransaction(
                transactionHash: hashData,
                blockchainTypeUid: spamInfo.blockchainType.uid,
                isSpam: isSpam,
                spamAddress: spamAddress
            )
            try? storage.save(scannedTransaction: scanned)

            result = isSpam
        }
        return result
    }

    // MARK: - Private Helpers

    /// Performs spam check in queue (already inside queue.sync)
    private func performCheckSpam(transactionHash: Data, record: TransactionRecord) -> Bool {
        // Double-check DB after entering queue
        if let scanned = try? storage.findScanned(transactionHash: transactionHash) {
            return scanned.isSpam
        }

        guard let spamInfo = spamTransactionInfoFactory.spamTransactionInfo(from: record) else {
            return false
        }

        let isSpam = evaluateSpam(spamInfo: spamInfo)
        let spamAddress = isSpam ? spamInfo.events.incoming.first?.address : nil

        let scanned = ScannedTransaction(
            transactionHash: transactionHash,
            blockchainTypeUid: record.source.blockchainType.uid,
            isSpam: isSpam,
            spamAddress: spamAddress
        )
        try? storage.save(scannedTransaction: scanned)

        // If not spam and has outgoing — add to cache
        if !isSpam, hasOutgoingEvents(record: record) {
            outputCache.add(record: record)
        }

        logger?.log(level: .debug, message: "SMNew: checked \(transactionHash.hs.hexString.prefix(8))... isSpam=\(isSpam)")

        return isSpam
    }
}

// MARK: - Factory

extension SpamManagerNew {
    static func instance(
        storage: ScannedTransactionStorage,
        accountManager: AccountManager,
        contactManager: ContactBookManager,
        logger _: Logger? = nil
    ) -> SpamManagerNew {
        let logger = Logger(minLogLevel: .debug)
        let outputCache = OutputTransactionCache(logger: logger)

        let filterChain = SpamFilterChain(logger: logger)
            .append(ContactsFilter(contactManager: contactManager, logger: logger))
            .append(ZeroValueFilter(logger: logger))

        let scoreEvaluator = SpamScoreEvaluator(logger: logger)
            .append(ZeroValueCondition(logger: logger))
            .append(AddressSimilarityCondition(cache: outputCache, logger: logger))
            .append(LowAmountCondition(logger: logger))
            .append(TimeCorrelationCondition(logger: logger))

        return SpamManagerNew(
            storage: storage,
            accountManager: accountManager,
            filterChain: filterChain,
            scoreEvaluator: scoreEvaluator,
            outputCache: outputCache,
            spamTransactionInfoFactory: SpamTransactionInfoFactory(),
            logger: logger
        )
    }
}
