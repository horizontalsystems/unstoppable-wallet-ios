import Foundation

class TransactionsLoader {
    private let dataSource: TransactionRecordDataSource

    weak var delegate: ITransactionLoaderDelegate?

    var loading = false

    init(dataSource: TransactionRecordDataSource) {
        self.dataSource = dataSource
    }

    var itemsCount: Int {
        dataSource.itemsCount
    }

    func item(forIndex index: Int) -> TransactionItem {
        dataSource.item(forIndex: index)
    }

    var allRecordsData: [Wallet: [TransactionRecord]] {
        dataSource.allRecordsData
    }

    func itemIndexes(coin: Coin, date: Date) -> [Int] {
        dataSource.itemIndexes(coin: coin, date: date)
    }

    func itemIndexesForPending(wallet: Wallet, blockHeight: Int) -> [Int] {
        dataSource.itemIndexesForPending(wallet: wallet, blockHeight: blockHeight)
    }

    func itemIndexesForLocked(wallet: Wallet, blockTimestamp: Int, oldBlockTimestamp: Int?) -> [Int] {
        dataSource.itemIndexesForLocked(wallet: wallet, blockTimestamp: blockTimestamp, oldBlockTimestamp: oldBlockTimestamp)
    }

    func set(wallets: [Wallet]) {
        dataSource.set(wallets: wallets)
    }

    func loadNext(initial: Bool = false) {
        guard !loading else {
            return
        }

        loading = true

        guard !dataSource.allShown else {
            if initial {
                //clear list on switch coins when data source has only one page
                delegate?.reload(with: dataSource.items, animated: true)
            }

            loading = false

            return
        }

        let fetchDataList = dataSource.fetchDataList

        if fetchDataList.isEmpty {
            let newItems = dataSource.increasePage()

            if initial, newItems != nil {
                delegate?.reload(with: dataSource.items, animated: true)
            } else if let newItems = newItems {
                delegate?.add(items: newItems)
            }

            loading = false
        } else {
            delegate?.fetchRecords(fetchDataList: fetchDataList, initial: initial)
        }
    }

    func didUpdate(records: [TransactionRecord], wallet: Wallet) {
        if let updatedArray = dataSource.handleUpdated(records: records, wallet: wallet) {
            delegate?.reload(with: updatedArray, animated: true)
        }
    }

    func didFetch(recordsData: [Wallet: [TransactionRecord]], initial: Bool) {
        dataSource.handleNext(recordsData: recordsData)

        // called after load next or when pool has not enough items
        if let items = dataSource.increasePage() {
            if initial {
                delegate?.reload(with: items, animated: true)
            } else {
                delegate?.add(items: items)
            }
        } else if initial {
            delegate?.reload(with: dataSource.items, animated: true)
        }

        loading = false
    }

    func handleUpdate(wallets: [Wallet]) {
        dataSource.handleUpdated(wallets: wallets)
    }

}
