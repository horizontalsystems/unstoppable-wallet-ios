import Foundation
import HsToolKit
import MarketKit

/// Per-adapter spam manager with serial queue processing.
///
/// Flow:
/// 1. Adapter creates SpamManager via SpamWrapper
/// 2. Adapter calls initialize(adapter:) to load cache and process unscanned transactions
/// 3. Adapter calls update(records:) for each transactionsSingle/transactionsObservable response
///
/// All operations are serialized in a single queue to ensure consistent cache state.
final class SpamManagerNew2 {
    private let queue: DispatchQueue

    private let accountId: String
    private let blockchainType: BlockchainType
    private let storage: ScannedTransactionStorage
    private let filterChain: SpamFilterChain
    private let scoreEvaluator: SpamScoreEvaluator
    private let outputCache: OutputTransactionCache
    private let logger: Logger?

    // MARK: - Initialization State

    private var isInitialized = false
    private let initCondition = NSCondition()
    private let initTimeout: TimeInterval = 30

    // MARK: - Init

    init(
        accountId: String,
        blockchainType: BlockchainType,
        storage: ScannedTransactionStorage,
        filterChain: SpamFilterChain,
        scoreEvaluator: SpamScoreEvaluator,
        outputCache: OutputTransactionCache,
        logger: Logger? = nil
    ) {
        self.accountId = accountId
        self.blockchainType = blockchainType
        self.storage = storage
        self.filterChain = filterChain
        self.scoreEvaluator = scoreEvaluator
        self.outputCache = outputCache
        self.logger = logger

        queue = DispatchQueue(label: "io.horizontalsystems.spam-manager.\(blockchainType.uid)", qos: .userInitiated)
    }

    private func threadName() -> String {
        if Thread.isMainThread {
            return "main"
        } else if let name = Thread.current.name, !name.isEmpty {
            return name
        } else {
            return "thread-\(Thread.current.hash)"
        }
    }

    // MARK: - Public API

    /// Initialize spam manager: load output cache and process unscanned transactions.
    /// Called once from adapter's init.
    /// Non-blocking - runs in background queue.
    func initialize(adapter: ITransactionsAdapter) {
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: initialize() called")
        queue.async { [weak self] in
            self?.performInitialize(adapter: adapter)
        }
    }

    /// Update records with spam flags.
    /// Called from transactionsSingle/transactionsObservable handlers.
    /// Blocks until initialization is complete and all records are processed.
    func update(items: [(record: TransactionRecord, spamInfo: SpamTransactionInfo?)]) -> [TransactionRecord] {
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: update() called with \(items.count) items")

        // Wait for initialization
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: waiting for init...")
        waitForInitialization()
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: init done, entering queue.sync...")

        // Process in queue
        var result = [TransactionRecord]()
        queue.sync { [weak self] in
            guard let self else { return }
            logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: inside queue.sync")
            result = performUpdate(items: items)
        }
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: update() returning \(result.count) records")
        return result
    }

    /// Check if address is known spam (from previously scanned transactions)
    func isSpam(address: String) -> Bool {
        (try? storage.findScanned(address: address))?.isSpam ?? false
    }

    // MARK: - Initialization

    private func performInitialize(adapter: ITransactionsAdapter) {
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: performInitialize started")

        // Step 1: Load output cache
        outputCache.loadCache(for: blockchainType, adapter: adapter)
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: cache loaded")

        // Step 2: Load and process unscanned transactions
        let spamScanState = try? storage.find(blockchainTypeUid: blockchainType.uid, accountUid: accountId)
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: loading transactions...")
        let transactions = loadTransactionsSync(adapter: adapter, afterPaginationData: spamScanState?.lastPaginationData)
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: loaded \(transactions.count) transactions")

        if !transactions.isEmpty {
            let sorted = transactions.sorted { $0.date < $1.date }
            let lastPaginationData = processTransactionsInternal(transactions: sorted)

            if let lastPaginationData {
                let newState = SpamScanState(
                    blockchainTypeUid: blockchainType.uid,
                    accountUid: accountId,
                    lastPaginationData: lastPaginationData
                )
                try? storage.save(spamScanState: newState)
            }
        }

        // Mark as initialized
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: marking initialized...")
        markInitialized()
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: initialized!")
    }

    private func loadTransactionsSync(adapter: ITransactionsAdapter, afterPaginationData: String?) -> [TransactionRecord] {
        let semaphore = DispatchSemaphore(value: 0)
        var transactions = [TransactionRecord]()

        _ = adapter
            .allTransactionsAfter(paginationData: afterPaginationData)
            .subscribe(
                onSuccess: { result in
                    transactions = result
                    semaphore.signal()
                },
                onError: { [weak self] error in
                    self?.logger?.log(level: .error, message: "SM: load error: \(error)")
                    semaphore.signal()
                }
            )

        semaphore.wait()
        return transactions
    }

    private func markInitialized() {
        initCondition.lock()
        isInitialized = true
        initCondition.broadcast()
        initCondition.unlock()
    }

    private func waitForInitialization() {
        initCondition.lock()
        defer { initCondition.unlock() }

        if isInitialized {
            logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: already initialized")
            return
        }

        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: waiting on condition...")
        let deadline = Date().addingTimeInterval(initTimeout)

        while !isInitialized {
            if !initCondition.wait(until: deadline) {
                logger?.log(level: .warning, message: "SM[\(blockchainType.uid)][\(threadName())]: TIMEOUT!")
                break
            }
        }
        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)][\(threadName())]: condition signaled, isInitialized=\(isInitialized)")
    }

    // MARK: - Update Records

    private func performUpdate(items: [(record: TransactionRecord, spamInfo: SpamTransactionInfo?)]) -> [TransactionRecord] {
        for item in items {
            let record = item.record

            guard let hashData = record.transactionHash.hs.hexData else {
                continue
            }

            // Check DB cache first
            if let scanned = try? storage.findScanned(transactionHash: hashData) {
                record.spam = scanned.isSpam
                continue
            }

            // Process and determine spam
            let isSpam = processRecord(record: record, hashData: hashData, spamInfo: item.spamInfo)
            record.spam = isSpam
        }

        return items.map(\.record)
    }

    /// Process single record: check spam, update cache, save to DB
    /// Returns isSpam result
    private func processRecord(record: TransactionRecord, hashData: Data, spamInfo: SpamTransactionInfo?) -> Bool {
        // Outgoing transactions: add to cache, not spam
        if isOutgoingRecord(record) {
            outputCache.add(record: record)

            let scanned = ScannedTransaction(
                transactionHash: hashData,
                blockchainTypeUid: blockchainType.uid,
                isSpam: false,
                spamAddress: nil
            )
            try? storage.save(scannedTransaction: scanned)

            logger?.log(level: .debug, message: "SM[\(blockchainType.uid)]: outgoing \(record.transactionHash)... -> cached")
            return false
        }

        // No spam info: save as not spam
        guard let spamInfo else {
            let scanned = ScannedTransaction(
                transactionHash: hashData,
                blockchainTypeUid: blockchainType.uid,
                isSpam: false,
                spamAddress: nil
            )
            try? storage.save(scannedTransaction: scanned)
            return false
        }

        // Evaluate spam
        let isSpam = evaluateSpam(spamInfo: spamInfo)
        let spamAddress = isSpam ? spamInfo.events.incoming.first?.address : nil

        let scanned = ScannedTransaction(
            transactionHash: hashData,
            blockchainTypeUid: blockchainType.uid,
            isSpam: isSpam,
            spamAddress: spamAddress
        )
        try? storage.save(scannedTransaction: scanned)

        logger?.log(level: .debug, message: "SM[\(blockchainType.uid)]: \(record.transactionHash)... isSpam=\(isSpam)")
        return isSpam
    }

    // MARK: - Internal Processing (for initialize)

    /// Process transactions during initialization (no spamInfo from converter)
    /// Returns last paginationData
    private func processTransactionsInternal(transactions: [TransactionRecord]) -> String? {
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

            // For internal processing, we need to create SpamTransactionInfo ourselves
            let spamInfo = createSpamInfo(from: record)
            _ = processRecord(record: record, hashData: hashData, spamInfo: spamInfo)

            lastPaginationData = record.paginationRaw
        }

        return lastPaginationData
    }

    /// Create SpamTransactionInfo from TransactionRecord (for internal use during initialization)
    private func createSpamInfo(from record: TransactionRecord) -> SpamTransactionInfo? {
        // Extract events based on record type
        var incomingEvents = [TransferEvent]()
        var outgoingEvents = [TransferEvent]()

        switch record {
        case let r as EvmIncomingTransactionRecord:
            incomingEvents.append(TransferEvent(address: r.from, value: r.value))

        case let r as ExternalContractCallTransactionRecord:
            incomingEvents = r.incomingEvents
            outgoingEvents = r.outgoingEvents

        case let r as TronIncomingTransactionRecord:
            incomingEvents.append(TransferEvent(address: r.from, value: r.value))

        case let r as TronExternalContractCallTransactionRecord:
            incomingEvents = r.incomingEvents
            outgoingEvents = r.outgoingEvents

        default:
            return nil
        }

        let events = TransferEvents(incoming: incomingEvents, outgoing: outgoingEvents)

        guard !events.isEmpty else {
            return nil
        }

        return SpamTransactionInfo(
            hash: record.transactionHash,
            blockchainType: blockchainType,
            timestamp: Int(record.date.timeIntervalSince1970),
            blockHeight: record.blockHeight,
            events: events
        )
    }

    // MARK: - Helpers

    private func isOutgoingRecord(_ record: TransactionRecord) -> Bool {
        switch record {
        case is EvmOutgoingTransactionRecord,
             is TronOutgoingTransactionRecord,
             is BitcoinOutgoingTransactionRecord,
             is MoneroOutgoingTransactionRecord:
            return true

        case let r as StellarTransactionRecord:
            if case .sendPayment = r.type { return true }
            return false

        case let r as ExternalContractCallTransactionRecord:
            return !r.outgoingEvents.isEmpty

        case let r as TronExternalContractCallTransactionRecord:
            return !r.outgoingEvents.isEmpty

        case let r as ContractCallTransactionRecord:
            return !r.outgoingEvents.isEmpty

        default:
            return false
        }
    }

    private func evaluateSpam(spamInfo: SpamTransactionInfo) -> Bool {
        logger?.log(level: .debug, message: "SM[]: SpamINFO: ============")
        logger?.log(level: .debug, message: "SM[]: hash: \(spamInfo.hash) \(spamInfo.timestamp) \(spamInfo.blockHeight?.description ?? "N/A")")
        logger?.log(level: .debug, message: "================ Events ======================")
        for t in spamInfo.events.incoming {
            logger?.log(level: .debug, message: "I: \(t.address) = \(t.value.formattedShort(signType: .always))")
        }
        for t in spamInfo.events.outgoing {
            logger?.log(level: .debug, message: "O: \(t.address) = \(t.value.formattedShort(signType: .always))")
        }

        // Step 1: Filters (fast checks)
        if let filterResult = filterChain.evaluate(spamInfo) {
            switch filterResult {
            case .spam:
                logger?.log(level: .debug, message: "SM[\(blockchainType.uid)]: filter -> spam")
                return true
            case .trusted:
                logger?.log(level: .debug, message: "SM[\(blockchainType.uid)]: filter -> trusted")
                return false
            case .ignore:
                break
            }
        }

        // Step 2: Score evaluation
        let context = SpamEvaluationContext(transaction: spamInfo)
        let decision = scoreEvaluator.evaluate(context)

        switch decision {
        case .spam:
            logger?.log(level: .debug, message: "SM[\(blockchainType.uid)]: score -> spam")
            return true
        case let .suspicious(score):
            logger?.log(level: .debug, message: "SM[\(blockchainType.uid)]: score -> suspicious(\(score))")
            return true
        case .trusted:
            return false
        }
    }
}
