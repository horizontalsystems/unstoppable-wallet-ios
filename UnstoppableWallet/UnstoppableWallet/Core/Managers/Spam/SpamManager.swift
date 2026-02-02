import Foundation
import HsToolKit
import MarketKit

/// Per-adapter spam manager with serial queue processing.
///
/// Flow:
/// 1. Adapter creates SpamManager via SpamWrapper
/// 2. Adapter calls initialize(adapter:) to load cache from DB and process unscanned transactions
/// 3. Adapter calls update(records:) for each transactionsSingle/transactionsObservable response
///
/// All operations are serialized in a single queue to ensure consistent cache state.
final class SpamManager {
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

    // MARK: - Public API

    /// Initialize spam manager: load output cache from DB and process unscanned transactions.
    /// Called once from adapter's init.
    /// Non-blocking — runs in background queue.
    func initialize(adapter: ITransactionsAdapter) {
        queue.async { [weak self] in
            self?.performInitialize(adapter: adapter)
        }
    }

    /// Mutates .spam flag on each record in-place.
    /// Records are reference types (class), so the caller's original array
    /// retains its order (e.g. descending from evmKit) while .spam is set
    /// by processing in ascending (oldest-first) order internally.
    func update(records: [TransactionRecord]) {
        waitForInitialization()

        // Sort ascending for correct spam detection
        // (output cache builds sequentially, AddressSimilarity + TimeCorrelation depend on order)
        let sorted = sorted(records)

        queue.sync { [weak self] in
            guard let self else { return }
            performUpdate(records: sorted)
        }
    }

    /// Check if address is known spam (from previously scanned transactions)
    func isSpam(address: String) -> Bool {
        (try? storage.findScanned(address: address))?.isSpam ?? false
    }

    // MARK: - Initialization

    private func performInitialize(adapter: ITransactionsAdapter) {
        // Step 1: Load output cache from DB (no adapter needed)
        outputCache.loadCache(for: blockchainType, accountId: accountId)

        // Step 2: Load and process unscanned transactions
        let spamScanState = try? storage.find(blockchainTypeUid: blockchainType.uid, accountUid: accountId)
        let transactions = loadTransactionsSync(adapter: adapter, afterPaginationData: spamScanState?.lastPaginationData)

        if !transactions.isEmpty {
            let sorted = sorted(transactions)
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

        markInitialized()
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
                    self?.logger?.log(level: .error, message: "SpamManager: load error: \(error)", context: ["SpamManager"], save: true)
                    semaphore.signal()
                }
            )

        semaphore.wait()
        return transactions
    }

    // MARK: - Initialization Synchronization

    private func markInitialized() {
        initCondition.lock()
        isInitialized = true
        initCondition.broadcast()
        initCondition.unlock()
    }

    private func waitForInitialization() {
        initCondition.lock()
        defer { initCondition.unlock() }

        if isInitialized { return }

        let deadline = Date().addingTimeInterval(initTimeout)
        while !isInitialized {
            if !initCondition.wait(until: deadline) {
                logger?.log(level: .warning, message: "SM[\(blockchainType.uid)]: init TIMEOUT")
                break
            }
        }
    }

    // MARK: - Update Records

    /// Mutates .spam on each record. No return value needed —
    /// caller holds references to the same objects.
    private func performUpdate(records: [TransactionRecord]) {
        for record in records {
            guard let hashData = record.transactionHash.hs.hexData else {
                continue
            }

            // Check DB cache first
            if let scanned = try? storage.findScanned(transactionHash: hashData) {
                record.spam = scanned.isSpam
                continue
            }

            let spamInfo = makeSpamInfo(from: record)
            record.spam = processRecord(record: record, hashData: hashData, spamInfo: spamInfo)
        }
    }

    // MARK: - Internal Processing (for initialize)

    private func processTransactionsInternal(transactions: [TransactionRecord]) -> String? {
        var lastPaginationData: String?

        for record in transactions {
            guard let hashData = record.transactionHash.hs.hexData else {
                continue
            }

            // Already scanned — skip
            if (try? storage.findScanned(transactionHash: hashData)) != nil {
                lastPaginationData = record.paginationRaw
                continue
            }

            let spamInfo = makeSpamInfo(from: record)
            _ = processRecord(record: record, hashData: hashData, spamInfo: spamInfo)
            lastPaginationData = record.paginationRaw
        }

        return lastPaginationData
    }

    // MARK: - Process Single Record

    /// Process single record: check spam, update caches, save to DB.
    /// Returns isSpam result.
    private func processRecord(record: TransactionRecord, hashData: Data, spamInfo: SpamTransactionInfo?) -> Bool {
        // Outgoing transactions: save addresses to cache/DB, mark not spam
        if let outgoingAddresses = OutputTransactionFactory.outgoingAddresses(from: record), !outgoingAddresses.isEmpty {
            outputCache.add(record: record, accountId: accountId)

            let scanned = ScannedTransaction(
                transactionHash: hashData,
                blockchainTypeUid: blockchainType.uid,
                isSpam: false,
                spamAddress: nil
            )
            try? storage.save(scannedTransaction: scanned)

            return false
        }

        // Outgoing without addresses (Bitcoin/Monero UTXO): mark not spam, no cache
        if OutputTransactionFactory.outgoingAddresses(from: record) != nil {
            let scanned = ScannedTransaction(
                transactionHash: hashData,
                blockchainTypeUid: blockchainType.uid,
                isSpam: false,
                spamAddress: nil
            )
            try? storage.save(scannedTransaction: scanned)
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

        return isSpam
    }

    // MARK: - Helpers

    /// Deterministic sort: oldest first → block position → hash as tiebreaker
    private func sorted(_ records: [TransactionRecord]) -> [TransactionRecord] {
        records.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }
            if lhs.transactionIndex != rhs.transactionIndex {
                return lhs.transactionIndex < rhs.transactionIndex
            }
            return lhs.transactionHash < rhs.transactionHash
        }
    }

    private func makeSpamInfo(from record: TransactionRecord) -> SpamTransactionInfo? {
        guard let eventProvider = record as? TransferEventsProvider else {
            return nil
        }
        return SpamTransactionInfo(
            hash: record.transactionHash,
            blockchainType: record.source.blockchainType,
            timestamp: Int(record.date.timeIntervalSince1970),
            blockHeight: record.blockHeight,
            events: eventProvider.transferEvents
        )
    }

    private func evaluateSpam(spamInfo: SpamTransactionInfo) -> Bool {
        // Step 1: Filters (fast checks)
        if let filterResult = filterChain.evaluate(spamInfo) {
            switch filterResult {
            case .spam:
                return true
            case .trusted:
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
            return true
        case let .suspicious(score):
            return false
        case .trusted:
            return false
        }
    }
}
