import RealmSwift

enum TransactionStatus {
    case pending
    case processing(confirmations: Int)
    case completed
}

extension TransactionStatus: Equatable {

    public static func ==(lhs: TransactionStatus, rhs: TransactionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending): return true
        case (let .processing(lhsConfirmations), let .processing(rhsConfirmations)): return lhsConfirmations == rhsConfirmations
        case (.completed, .completed): return true
        default: return false
        }
    }

}

protocol ITransactionsView: class {
    func set(title: String)
    func show(filters: [TransactionFilterItem])
    func reload()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onTransactionItemClick(transaction: TransactionViewItem)
    func onFilterSelect(coinCode: CoinCode?)

    var itemsCount: Int { get }
    func item(forIndex index: Int) -> TransactionViewItem
}

protocol ITransactionsInteractor {
    func retrieveFilters()
    func set(coinCode: CoinCode?)

    var recordsCount: Int { get }
    func record(forIndex index: Int) -> TransactionRecord
}

protocol ITransactionsInteractorDelegate: class {
    func didRetrieve(filters: [CoinCode])
    func didUpdateDataSource()
}

protocol ITransactionsRouter {
    func openTransactionInfo(transactionHash: String)
}

protocol ITransactionRecordDataSource {
    var delegate: ITransactionRecordDataSourceDelegate? { get set }

    var count: Int { get }
    func record(forIndex index: Int) -> TransactionRecord
    func set(coinCode: CoinCode?)
}

protocol ITransactionRecordDataSourceDelegate: class {
    func onUpdateResults()
}
