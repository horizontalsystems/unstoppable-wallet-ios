import Foundation

protocol ITransactionsView: class {
    func show(filters: [TransactionFilterItem])
    func show(items: [TransactionRecordViewItem])
    func didRefresh()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onTransactionItemClick(transaction: TransactionRecordViewItem, coin: Coin, txHash: String)
    func refresh()
    func onFilterSelect(coin: Coin?)
}

protocol ITransactionsInteractor {
    func retrieveFilters()
    func retrieveTransactionItems(coin: Coin?)
}

protocol ITransactionsInteractorDelegate: class {
    func didRetrieve(filters: [Coin])
    func didRetrieve(items: [TransactionRecordViewItem])
}

protocol ITransactionsRouter {
    func showTransactionInfo(transaction: TransactionRecordViewItem, coin: Coin, txHash: String)
}
