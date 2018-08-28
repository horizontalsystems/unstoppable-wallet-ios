import Foundation

protocol ITransactionsView: class {
    func show(filters: [TransactionFilterItem])
    func show(items: [TransactionRecordViewItem])
    func didRefresh()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onTransactionItemClick(transaction: TransactionRecordViewItem, coinCode: String, txHash: String)
    func refresh()
    func onFilterSelect(adapterId: String?)
}

protocol ITransactionsInteractor {
    func retrieveFilters()
    func retrieveTransactionItems(adapterId: String?)
}

protocol ITransactionsInteractorDelegate: class {
    func didRetrieve(filters: [TransactionFilter])
    func didRetrieve(items: [TransactionRecordViewItem])
}

protocol ITransactionsRouter {
    func showTransactionInfo(transaction: TransactionRecordViewItem, coinCode: String, txHash: String)
}
