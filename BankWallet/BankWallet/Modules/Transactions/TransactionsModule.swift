import RealmSwift

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
    func set(title: String)
    func show(filters: [TransactionFilterItem])
    func didRefresh()
    func reload()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onTransactionItemClick(transaction: TransactionViewItem)
    func refresh()
    func onFilterSelect(coin: Coin?)

    var itemsCount: Int { get }
    func item(forIndex index: Int) -> TransactionViewItem
}

protocol ITransactionsInteractor {
    func retrieveFilters()
    func refresh()
    func set(coin: Coin?)

    var baseCurrency: Currency { get }
    var recordsCount: Int { get }
    func record(forIndex index: Int) -> TransactionRecord
    func adapter(forCoin coin: Coin) -> IAdapter?
}

protocol ITransactionsInteractorDelegate: class {
    func didRetrieve(filters: [Coin])
    func didUpdateDataSource()
    func didRefresh()
}

protocol ITransactionsRouter {
    func openTransactionInfo(transaction: TransactionViewItem)
}

protocol ITransactionRecordDataSource {
    var delegate: ITransactionRecordDataSourceDelegate? { get set }

    var count: Int { get }
    func record(forIndex index: Int) -> TransactionRecord
    func set(coin: Coin?)
}

protocol ITransactionRecordDataSourceDelegate: class {
    func onUpdateResults()
}
