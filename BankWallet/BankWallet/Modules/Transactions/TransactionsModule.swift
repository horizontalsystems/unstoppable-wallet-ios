import Foundation
import DeepDiff
import CurrencyKit

enum TransactionStatus {
    case failed
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
    func show(filters: [Wallet?])
    func show(transactions: [TransactionViewItem], animated: Bool)
    func showNoTransactions()
    func reloadTransactions()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onFilterSelect(wallet: Wallet?)

    func onBottomReached()

    func onTransactionClick(item: TransactionViewItem)
    func willShow(item: TransactionViewItem)
}

protocol ITransactionsInteractor {
    func initialFetch()
    func fetchLastBlockHeights()

    func fetchRecords(fetchDataList: [FetchData], initial: Bool)
    func set(selectedWallets: [Wallet])

    func fetchRate(coin: Coin, date: Date)
}

protocol ITransactionsInteractorDelegate: class {
    func onUpdate(selectedCoins: [Wallet])
    func onUpdate(walletsData: [(Wallet, Int, LastBlockInfo?)])
    func onUpdateBaseCurrency()
    func onConnectionRestore()

    func onUpdate(lastBlockInfo: LastBlockInfo, wallet: Wallet)

    func didUpdate(records: [TransactionRecord], wallet: Wallet)

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date)
    func didFetch(recordsData: [Wallet: [TransactionRecord]], initial: Bool)
}

protocol ITransactionsRouter {
    func openTransactionInfo(viewItem: TransactionViewItem)
}

protocol ITransactionViewItemFactory {
    func viewItem(fromRecord: TransactionRecord, wallet: Wallet, lastBlockInfo: LastBlockInfo?, threshold: Int?, rate: CurrencyValue?) -> TransactionViewItem
}

protocol IDiffer {
    func changes<T: DiffAware>(old: [T], new: [T]) -> [Change<T>]
}

struct FetchData {
    let wallet: Wallet
    let from: TransactionRecord?
    let limit: Int
}
