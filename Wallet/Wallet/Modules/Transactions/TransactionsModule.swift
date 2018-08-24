import Foundation

protocol ITransactionsView: class {
    func show(items: [TransactionRecordViewItem], changeSet: CollectionChangeSet?)
    func didRefresh()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onTransactionItemClick(transaction: TransactionRecordViewItem, coinCode: String, txHash: String) //transaction is stab. need to fetch from db
    func refresh()
}

protocol ITransactionsInteractor {
    func retrieveTransactionRecords()
}

protocol ITransactionsInteractorDelegate: class {
    func didRetrieve(items: [TransactionRecordViewItem], changeSet: CollectionChangeSet?)
}

protocol ITransactionsRouter {
    func showTransactionInfo(transaction: TransactionRecordViewItem, coinCode: String, txHash: String)
}
