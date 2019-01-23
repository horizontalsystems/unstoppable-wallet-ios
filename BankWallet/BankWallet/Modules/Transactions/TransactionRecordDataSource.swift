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

    var allRecords: [CoinCode: [TransactionRecord]] {
        var records = [CoinCode: [TransactionRecord]]()

        for pool in poolRepo.activePools {
            records[pool.coinCode] = pool.records
        }

        return records
    }

    func item(forIndex index: Int) -> TransactionItem {
        return itemsDataSource.item(forIndex: index)
    }

    func itemIndexes(coinCode: CoinCode, timestamp: Double) -> [Int] {
        return itemsDataSource.itemIndexes(coinCode: coinCode, timestamp: timestamp)
    }

    var fetchDataList: [FetchData] {
        return poolRepo.activePools.compactMap { pool in
            pool.getFetchData(limit: limit)
        }
    }

    func handleNext(records: [CoinCode: [TransactionRecord]]) {
        records.forEach { coinCode, records in
            poolRepo.pool(byCoinCode: coinCode)?.add(records: records)
        }
    }

    func handleUpdated(records: [TransactionRecord], coinCode: CoinCode) -> Bool {
        guard let pool = poolRepo.pool(byCoinCode: coinCode) else {
            return false
        }

        var updatedRecords = [TransactionRecord]()
        var insertedRecords = [TransactionRecord]()
        var newData = false

        for record in records {
            switch pool.handleUpdated(record: record) {
            case .updated: updatedRecords.append(record)
            case .inserted: insertedRecords.append(record)
            case .newData:
                if itemsDataSource.shouldInsert(record: record) {
                    insertedRecords.append(record)
                    pool.increaseFirstUnusedIndex()
                }
                newData = true
            case .ignored: ()
            }
        }

//        print("Handled Records: updated: \(updatedRecords.count), inserted: \(insertedRecords.count), new data: \(newData)")

        guard poolRepo.isPoolActive(coinCode: coinCode) else {
            return false
        }

        guard !updatedRecords.isEmpty || !insertedRecords.isEmpty else {
            return newData
        }

        let updatedItems = updatedRecords.map { factory.create(coinCode: coinCode, record: $0) }
        let insertedItems = insertedRecords.map { factory.create(coinCode: coinCode, record: $0) }

        itemsDataSource.handle(updatedItems: updatedItems, insertedItems: insertedItems)

        return true
    }

    func increasePage() -> Bool {
        var unusedItems = [TransactionItem]()

        poolRepo.activePools.forEach { pool in
            pool.unusedRecords.forEach { record in
                unusedItems.append(factory.create(coinCode: pool.coinCode, record: record))
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
            poolRepo.pool(byCoinCode: item.coinCode)?.increaseFirstUnusedIndex()
        }

        return true
    }

    func set(coinCodes: [CoinCode]) {
        poolRepo.allPools.forEach { pool in
            pool.resetFirstUnusedIndex()
        }

        poolRepo.activatePools(coinCodes: coinCodes)
        itemsDataSource.clear()
    }

}
