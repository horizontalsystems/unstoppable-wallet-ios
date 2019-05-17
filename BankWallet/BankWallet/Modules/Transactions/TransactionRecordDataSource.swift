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

    var allRecordsData: [Coin: [TransactionRecord]] {
        var recordsData = [Coin: [TransactionRecord]]()

        for pool in poolRepo.allPools {
            recordsData[pool.coin] = pool.records
        }

        return recordsData
    }

    func item(forIndex index: Int) -> TransactionItem {
        return itemsDataSource.item(forIndex: index)
    }

    func itemIndexes(coin: Coin, date: Date) -> [Int] {
        return itemsDataSource.itemIndexes(coin: coin, date: date)
    }

    func itemIndexesForPending(coin: Coin, blockHeight: Int) -> [Int] {
        return itemsDataSource.recordIndexes(greaterThan: blockHeight, coin: coin)
    }

    var fetchDataList: [FetchData] {
        return poolRepo.activePools.compactMap { pool in
            pool.getFetchData(limit: limit)
        }
    }

    func handleNext(recordsData: [Coin: [TransactionRecord]]) {
        recordsData.forEach { coin, records in
            poolRepo.pool(byCoin: coin)?.add(records: records)
        }
    }

    func handleUpdated(records: [TransactionRecord], coin: Coin) -> [TransactionItem]? {
        guard let pool = poolRepo.pool(byCoin: coin) else {
            return nil
        }

        for record in records {
            switch pool.handleUpdated(record: record) {
            case .updated: ()
            case .inserted: ()
            case .newData:
                if itemsDataSource.shouldInsert(record: record) {
                    pool.increaseFirstUnusedIndex()
                }
            case .ignored: ()
            }
        }

        guard poolRepo.isPoolActive(coin: coin) else {
            return nil
        }

        let items = records.map { factory.create(coin: coin, record: $0) }
        return itemsDataSource.handle(newItems: items)
    }

    func increasePage() -> Bool {
        var unusedItems = [TransactionItem]()

        poolRepo.activePools.forEach { pool in
            pool.unusedRecords.forEach { record in
                unusedItems.append(factory.create(coin: pool.coin, record: record))
            }
        }

        guard !unusedItems.isEmpty else {
            return false
        }

        unusedItems.sort()
        unusedItems.reverse()

        let usedItems = Array(unusedItems.prefix(limit))

        itemsDataSource.add(items: usedItems)

        usedItems.forEach { item in
            poolRepo.pool(byCoin: item.coin)?.increaseFirstUnusedIndex()
        }

        return true
    }

    func set(coins: [Coin]) {
        poolRepo.allPools.forEach { pool in
            pool.resetFirstUnusedIndex()
        }

        poolRepo.activatePools(coins: coins)
        itemsDataSource.clear()
    }

}
