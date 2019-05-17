import Foundation

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

    func itemIndexes(coin: Coin, date: Date) -> [Int] {
        return dataSource.itemIndexes(coin: coin, date: date)
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

            delegate?.reload(with: dataSource.items, animated: !initial)

            loading = false

            return
        }

        let fetchDataList = dataSource.fetchDataList

        if fetchDataList.isEmpty {
//            print("Load Next: fetch data list is empty")

            if dataSource.increasePage() {
                delegate?.reload(with: dataSource.items, animated: true)
            }

            loading = false
        } else {
//            print("Load Next: fetch: \(fetchDataList.map { data -> String in "\(data.coin) -- \(data.limit) -- \(data.hashFrom ?? "nil")" })")

            delegate?.fetchRecords(fetchDataList: fetchDataList)
        }
    }

    func didUpdate(records: [TransactionRecord], coin: Coin) {
        if let updatedArray = dataSource.handleUpdated(records: records, coin: coin) {
            delegate?.reload(with: updatedArray, animated: true)
        }
    }

    func didFetch(recordsData: [Coin: [TransactionRecord]]) {
        dataSource.handleNext(recordsData: recordsData)

        //called after load next
        if dataSource.increasePage() {
            delegate?.reload(with: dataSource.items, animated: false)
        }

        loading = false
    }

}
