import Foundation

protocol ITransactionsView: class {
    func show(filters: [TransactionFilter])
    func show(items: [TransactionRecordViewItem])
    func didRefresh()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onTransactionItemClick(transaction: TransactionRecordViewItem, coinCode: String, txHash: String)
    func refresh()
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
