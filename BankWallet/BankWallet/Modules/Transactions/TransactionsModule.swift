import Foundation
import DeepDiff

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
    func reload(with diff: [Change<TransactionViewItem>], items: [TransactionViewItem], animated: Bool)
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onFilterSelect(coin: Coin?)

    func onBottomReached()

    func onTransactionClick(item: TransactionViewItem)
    func willShow(item: TransactionViewItem)
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
    func reload(with newItems: [TransactionItem], animated: Bool)
    func add(items: [TransactionItem])
}

protocol ITransactionViewItemFactory {
    func viewItem(fromItem item: TransactionItem, lastBlockHeight: Int?, threshold: Int?, rate: CurrencyValue?) -> TransactionViewItem
}

protocol ITransactionViewItemLoader {
    func reload(with newItems: [TransactionItem], animated: Bool)
    func reloadAll()
    func reload(indexes: [Int])
    func add(items: [TransactionItem])
}

protocol ITransactionViewItemLoaderDelegate: class {
    func createViewItem(for item: TransactionItem) -> TransactionViewItem
    func reload(with diff: [Change<TransactionViewItem>], items: [TransactionViewItem], animated: Bool)
}

protocol IDiffer {
    func changes<T: DiffAware>(old: [T], new: [T]) -> [Change<T>]
}

struct FetchData {
    let coin: Coin
    let from: (hash: String, interTransactionIndex: Int)?
    let limit: Int
}
