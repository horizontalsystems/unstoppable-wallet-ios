import RealmSwift

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
    func realmResults(forCoin coin: Coin?) -> Results<TransactionRecord>
}

protocol ITransactionsInteractorDelegate: class {
    func didRetrieve(filters: [Coin])
}

protocol ITransactionsRouter {
    func openTransactionInfo(transaction: TransactionRecordViewItem)
}
