class TransactionsLoader {
    private let dataSource: TransactionRecordDataSource

    weak var delegate: ITransactionLoaderDelegate?

    var loading = false

    init(dataSource: TransactionRecordDataSource) {
        self.dataSource = dataSource
    }

    var itemsCount: Int {
        return dataSource.itemsCount
    }

    func item(forIndex index: Int) -> TransactionItem {
        return dataSource.item(forIndex: index)
    }

    var allRecordsData: [Coin: [TransactionRecord]] {
        return dataSource.allRecordsData
    }

    func itemIndexes(coin: Coin, timestamp: Double) -> [Int] {
        return dataSource.itemIndexes(coin: coin, timestamp: timestamp)
    }

    func itemIndexesForPending(coin: Coin, blockHeight: Int) -> [Int] {
        return dataSource.itemIndexesForPending(coin: coin, blockHeight: blockHeight)
    }

    func set(coins: [Coin]) {
        dataSource.set(coins: coins)
    }

    func loadNext(initial: Bool = false) {
        guard !loading else {
//            print("Already Loading")
            return
        }

        loading = true

//        print("Load Next: \(initial ? "initial" : "paging")")

        guard !dataSource.allShown else {
//            print("Load Next: all shown")

            if initial {
                delegate?.didChangeData()
            }

            loading = false

            return
        }

        let fetchDataList = dataSource.fetchDataList

        if fetchDataList.isEmpty {
//            print("Load Next: fetch data list is empty")

            if dataSource.increasePage() {
                delegate?.didChangeData()
            }

            loading = false
        } else {
//            print("Load Next: fetch: \(fetchDataList.map { data -> String in "\(data.coin) -- \(data.limit) -- \(data.hashFrom ?? "nil")" })")

            delegate?.fetchRecords(fetchDataList: fetchDataList)
        }
    }

    func didUpdate(records: [TransactionRecord], coin: Coin) {
        delegate?.reload(with: dataSource.handleUpdated(records: records, coin: coin))
    }

    func didFetch(recordsData: [Coin: [TransactionRecord]]) {
        dataSource.handleNext(recordsData: recordsData)

        if dataSource.increasePage() {
            delegate?.didChangeData()
        }

        loading = false
    }

}
