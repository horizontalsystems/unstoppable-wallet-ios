import Foundation
import HsToolKit
import MarketKit
import RxSwift

// Synchronous cache of outgoing transactions for address poisoning detection
final class OutputTransactionCache {
    private let cacheSize: Int
    private let factory: OutputTransactionFactory
    private let logger: Logger?
    
    // In-memory cache by blockchainType
    private var cache: [BlockchainType: [CachedOutputTransaction]] = [:]
    
    private let disposeBag = DisposeBag()
    
    init(factory: OutputTransactionFactory = OutputTransactionFactory(), cacheSize: Int = 10, logger: Logger? = nil) {
        self.factory = factory
        self.cacheSize = cacheSize
        self.logger = logger
    }
    
    /// Synchronously retrieves cached transactions for a blockchain.
    /// If no cache exists — returns empty array (cache should be pre-loaded)
    func get(blockchainType: BlockchainType) -> [CachedOutputTransaction] {
        if let cached = cache[blockchainType] {
            return cached
        }
        
        return []
    }
    
    /// Synchronously loads cache for a blockchain from adapter.
    /// Called during SpamManager initialization in its queue.
    func loadCache(for blockchainType: BlockchainType, adapter: ITransactionsAdapter) {
        let semaphore = DispatchSemaphore(value: 0)
        var records = [TransactionRecord]()
        
        adapter.transactionsSingle(
            paginationData: nil,
            token: nil,
            filter: .outgoing,
            address: nil,
            limit: cacheSize
        )
        .subscribe(
            onSuccess: { result in
                records = result
                semaphore.signal()
            },
            onError: { [weak self] error in
                self?.logger?.log(level: .error, message: "OTCache: Failed to load for \(blockchainType.uid): \(error)")
                semaphore.signal()
            }
        )
        .disposed(by: disposeBag)
        
        semaphore.wait()
        
        let cached = records.compactMap { factory.cachedOutput(from: $0) }
        cache[blockchainType] = cached
        
        logger?.log(level: .debug, message: "OTCache: loaded for \(blockchainType.uid): \(cached.count) items")
    }
    
    /// Synchronously adds transaction to cache (maintains timestamp sorting)
    func add(record: TransactionRecord) {
        let blockchainType = record.source.blockchainType
        
        guard let cached = factory.cachedOutput(from: record) else {
            logger?.log(level: .debug, message: "OTCache: Cannot create cached output from record")
            return
        }
        
        var transactions = cache[blockchainType] ?? []
        
        // Check duplicate
        if transactions.contains(where: { $0.address == cached.address && $0.timestamp == cached.timestamp }) {
            return
        }
        
        // Insert in sorted order (newest first)
        let insertIndex = transactions.firstIndex { cached.timestamp > $0.timestamp } ?? transactions.endIndex
        transactions.insert(cached, at: insertIndex)
        
        // Trim to cache size
        if transactions.count > cacheSize {
            transactions = Array(transactions.prefix(cacheSize))
        }
        
        cache[blockchainType] = transactions
        
        logger?.log(level: .debug, message: "OTCache: Added to cache \(blockchainType.uid): \(cached.address.prefix(8))...")
    }
    
    /// Clears entire cache
    func clear() {
        let count = cache.values.reduce(0) { $0 + $1.count }
        cache.removeAll()
        logger?.log(level: .debug, message: "OTCache: cleared: \(count) items removed")
    }
    
    /// Clears cache for specific blockchain
    func clear(blockchainType: BlockchainType) {
        let count = cache[blockchainType]?.count ?? 0
        cache[blockchainType] = nil
        logger?.log(level: .debug, message: "OTCache: cleared for \(blockchainType.uid): \(count) items removed")
    }
}
