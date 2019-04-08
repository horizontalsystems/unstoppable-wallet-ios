import Foundation

enum TransactionStatus {
    case pending
    case processing(progress: Double)
    case completed
}

extension TransactionStatus: Equatable {

    public static func ==(lhs: TransactionStatus, rhs: TransactionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending): return true
        case (let .processing(lhsProgress), let .processing(rhsProgress)): return lhsProgress == rhsProgress
        case (.completed, .completed): return true
        default: return false
        }
    }

}

protocol ITransactionsView: class {
    func show(filters: [Coin?])
    func reload()
    func reload(indexes: [Int])
    func reload(with diff: [IndexChange])
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onViewAppear()
    func onFilterSelect(coin: Coin?)

    var itemsCount: Int { get }
    func item(forIndex index: Int) -> TransactionViewItem
    func onBottomReached()

    func onTransactionItemClick(index: Int)
}

protocol ITransactionsInteractor {
    func initialFetch()
    func fetchLastBlockHeights()

    func fetchRecords(fetchDataList: [FetchData])
    func set(selectedCoins: [Coin])

    func fetchRate(coin: Coin, date: Date)
}

protocol ITransactionsInteractorDelegate: class {
    func onUpdate(selectedCoins: [Coin])
    func onUpdate(coinsData: [(Coin, Int, Int?)])
    func onUpdateBaseCurrency()

    func onUpdate(lastBlockHeight: Int, coin: Coin)

    func didUpdate(records: [TransactionRecord], coin: Coin)

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date)
    func didFetch(recordsData: [Coin: [TransactionRecord]])
    func onConnectionRestore()
}

protocol ITransactionsRouter {
    func openTransactionInfo(viewItem: TransactionViewItem)
}

protocol ITransactionLoaderDelegate: class {
    func fetchRecords(fetchDataList: [FetchData])
    func didChangeData()
    func reload(with diff: [IndexChange])
}

protocol ITransactionViewItemFactory {
    func viewItem(fromItem item: TransactionItem, lastBlockHeight: Int?, threshold: Int?, rate: CurrencyValue?) -> TransactionViewItem
}

struct FetchData {
    let coin: Coin
    let hashFrom: String?
    let limit: Int
}

enum IndexChange {
    case insert(index: Int)
    case update(index: Int)
    case move(fromIndex: Int, toIndex: Int)
}
