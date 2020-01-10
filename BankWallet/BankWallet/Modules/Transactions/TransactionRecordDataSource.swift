import Foundation

class TransactionRecordDataSource {
    private let poolRepo: TransactionRecordPoolRepo
    private let itemsDataSource: TransactionItemDataSource
    private let factory: TransactionItemFactory
    private let limit: Int

    init(poolRepo: TransactionRecordPoolRepo, itemsDataSource: TransactionItemDataSource, factory: TransactionItemFactory, limit: Int = 10) {
        self.poolRepo = poolRepo
        self.itemsDataSource = itemsDataSource
        self.factory = factory
        self.limit = limit
    }

    var items: [TransactionItem] {
        return itemsDataSource.items
    }

    var itemsCount: Int {
        return itemsDataSource.count
    }

    var allShown: Bool {
        for pool in poolRepo.activePools {
            if !pool.allShown {
                return false
            }
        }

        return true
    }

    var allRecordsData: [Wallet: [TransactionRecord]] {
        var recordsData = [Wallet: [TransactionRecord]]()

        for pool in poolRepo.allPools {
            recordsData[pool.wallet] = pool.records
        }

        return recordsData
    }

    func item(forIndex index: Int) -> TransactionItem {
        itemsDataSource.item(forIndex: index)
    }

    func itemIndexes(coin: Coin, date: Date) -> [Int] {
        itemsDataSource.itemIndexes(coin: coin, date: date)
    }

    func itemIndexesForPending(wallet: Wallet, blockHeight: Int) -> [Int] {
        itemsDataSource.recordIndexes(greaterThan: blockHeight, wallet: wallet)
    }

    func itemIndexesForLocked(wallet: Wallet, blockTimestamp: Int, oldBlockTimestamp: Int?) -> [Int] {
        itemsDataSource.recordIndexes(unlockingBefore: blockTimestamp, oldBlockTimestamp: oldBlockTimestamp, wallet: wallet)
    }

    var fetchDataList: [FetchData] {
        poolRepo.activePools.compactMap { pool in
            pool.getFetchData(limit: limit)
        }
    }

    func handleNext(recordsData: [Wallet: [TransactionRecord]]) {
        recordsData.forEach { wallet, records in
            poolRepo.pool(byWallet: wallet)?.add(records: records)
        }
    }

    func handleUpdated(records: [TransactionRecord], wallet: Wallet) -> [TransactionItem]? {
        guard let pool = poolRepo.pool(byWallet: wallet) else {
            return nil
        }
        var handledItems = [TransactionRecord]()

        for record in records.sorted() {
            switch pool.handleUpdated(record: record) {
            case .updated: handledItems.append(record)
            case .inserted: handledItems.append(record)
            case .newData:
                if itemsDataSource.shouldInsert(record: record) {
                    handledItems.append(record)
                    pool.increaseFirstUnusedIndex()
                }
            case .ignored: ()
            }
        }

        guard poolRepo.isPoolActive(wallet: wallet) else {
            return nil
        }

        let items = handledItems.map { factory.create(wallet: wallet, record: $0) }
        return itemsDataSource.handle(newItems: items)
    }

    func increasePage() -> [TransactionItem]? {
        var unusedItems = [TransactionItem]()

        poolRepo.activePools.forEach { pool in
            pool.unusedRecords.forEach { record in
                unusedItems.append(factory.create(wallet: pool.wallet, record: record))
            }
        }

        guard !unusedItems.isEmpty else {
            return nil
        }

        unusedItems.sort()
        unusedItems.reverse()

        let usedItems = Array(unusedItems.prefix(limit))

        itemsDataSource.add(items: usedItems)

        usedItems.forEach { item in
            poolRepo.pool(byWallet: item.wallet)?.increaseFirstUnusedIndex()
        }

        return usedItems
    }

    func set(wallets: [Wallet]) {
        poolRepo.allPools.forEach { pool in
            pool.resetFirstUnusedIndex()
        }

        poolRepo.activatePools(wallets: wallets)
        itemsDataSource.clear()
    }

    func handleUpdated(wallets: [Wallet]) {
        let unusedWallets = poolRepo.allPools.filter { pool in
            !wallets.contains(pool.wallet)
        }.map { pool in
            pool.wallet
        }
        poolRepo.deactivate(wallets: unusedWallets)

        set(wallets: wallets)
    }

}
