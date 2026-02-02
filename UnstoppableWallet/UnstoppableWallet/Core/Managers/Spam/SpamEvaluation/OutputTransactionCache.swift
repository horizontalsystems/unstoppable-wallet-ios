import Foundation
import HsToolKit
import MarketKit

/// In-memory cache backed by DB storage.
/// All writes go to both DB and memory.
/// Initial load from DB — no adapter dependency.
final class OutputTransactionCache {
    private let cacheSize: Int
    private let factory: OutputTransactionFactory
    private let storage: ScannedTransactionStorage
    private let logger: Logger?

    private var cache: [BlockchainType: [CachedOutputTransaction]] = [:]

    init(
        storage: ScannedTransactionStorage,
        factory: OutputTransactionFactory = OutputTransactionFactory(),
        cacheSize: Int = 10,
        logger: Logger? = nil
    ) {
        self.storage = storage
        self.factory = factory
        self.cacheSize = cacheSize
        self.logger = logger
    }

    // MARK: - Read

    /// Returns cached outgoing addresses for blockchain.
    /// Must be called after loadCache().
    func get(blockchainType: BlockchainType) -> [CachedOutputTransaction] {
        cache[blockchainType] ?? []
    }

    // MARK: - Load from DB

    /// Loads cache from DB. Called during SpamManager initialization (in its serial queue).
    /// No semaphores, no adapter — pure DB read.
    func loadCache(for blockchainType: BlockchainType, accountId: String) {
        do {
            let rows = try storage.loadOutgoingAddresses(
                blockchainTypeUid: blockchainType.uid,
                accountUid: accountId,
                limit: cacheSize
            )

            cache[blockchainType] = rows.map {
                CachedOutputTransaction(
                    address: $0.address,
                    timestamp: $0.timestamp,
                    blockHeight: $0.blockHeight
                )
            }
        } catch {
            logger?.log(level: .error, message: "OTCache: DB load failed for \(blockchainType.uid): \(error)", context: ["SpamManager"], save: true)
            cache[blockchainType] = []
        }
    }

    // MARK: - Write

    /// Saves outgoing record to DB and updates in-memory cache.
    func add(record: TransactionRecord, accountId: String) {
        let blockchainType = record.source.blockchainType
        let outputs = factory.cachedOutputs(from: record)

        guard !outputs.isEmpty else {
            return
        }

        // Save to DB
        let dbRecords = outputs.map {
            OutgoingAddress(
                address: $0.address,
                blockchainTypeUid: blockchainType.uid,
                accountUid: accountId,
                timestamp: $0.timestamp,
                blockHeight: $0.blockHeight
            )
        }

        do {
            try storage.save(outgoingAddresses: dbRecords)
        } catch {
            logger?.log(level: .error, message: "OTCache: DB save failed: \(error)", context: ["SpamManager"], save: true)
        }

        // Update in-memory cache
        var transactions = cache[blockchainType] ?? []

        for cached in outputs {
            transactions.removeAll { $0.address == cached.address }
            transactions.insert(cached, at: 0)
        }

        if transactions.count > cacheSize {
            transactions = Array(transactions.prefix(cacheSize))
        }

        cache[blockchainType] = transactions
    }

    // MARK: - Clear

    func clear() {
        cache.removeAll()
    }

    func clear(blockchainType: BlockchainType) {
        cache[blockchainType] = nil
    }
}
