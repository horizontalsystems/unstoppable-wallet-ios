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

    var allRecordsData: [CoinCode: [TransactionRecord]] {
        return dataSource.allRecordsData
    }

    func itemIndexes(coinCode: CoinCode, timestamp: Double) -> [Int] {
        return dataSource.itemIndexes(coinCode: coinCode, timestamp: timestamp)
    }

    func itemIndexes(coinCode: CoinCode, lastBlockHeight: Int, threshold: Int) -> [Int] {
        return dataSource.itemIndexes(coinCode: coinCode, lastBlockHeight: lastBlockHeight, threshold: threshold)
    }

    func set(coinCodes: [CoinCode]) {
        dataSource.set(coinCodes: coinCodes)
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
//            print("Load Next: fetch: \(fetchDataList.map { data -> String in "\(data.coinCode) -- \(data.limit) -- \(data.hashFrom ?? "nil")" })")

            delegate?.fetchRecords(fetchDataList: fetchDataList)
        }
    }

    func didUpdate(records: [TransactionRecord], coinCode: CoinCode) {
//        print("Did Update Records: \(records.count) --- \(coinCode)")

//            print("Update Records Needs Reload")

            delegate?.reload(with: dataSource.handleUpdated(records: records, coinCode: coinCode))
    }

    func didFetch(recordsData: [CoinCode: [TransactionRecord]]) {
        dataSource.handleNext(recordsData: recordsData)

        if dataSource.increasePage() {
            delegate?.didChangeData()
        }

        loading = false
    }

}
