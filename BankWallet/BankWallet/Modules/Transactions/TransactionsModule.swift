import RealmSwift

enum TransactionStatus {
    case processing
    case verifying(progress: Double)
    case completed
}

protocol ITransactionsView: class {
    func set(title: String)
    func show(filters: [TransactionFilterItem])
    func didRefresh()
    func reload()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onTransactionItemClick(transaction: TransactionRecordViewItem)
    func refresh()
    func onFilterSelect(coin: Coin?)

    var itemsCount: Int { get }
    func item(forIndex index: Int) -> TransactionRecordViewItem
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
    func openTransactionInfo(transaction: TransactionRecordViewItem)
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
