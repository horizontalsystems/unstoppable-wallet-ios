import Foundation

class TransactionsPresenter {

    weak var view: ITransactionsView?
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        interactor.retrieveTransactionRecords()
    }

    func onTransactionItemClick(transaction: TransactionRecordViewItem, coinCode: String, txHash: String) {
        router.showTransactionInfo(transaction: transaction, coinCode: coinCode, txHash: txHash)
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func didRetrieve(items: [TransactionRecordViewItem], changeSet: CollectionChangeSet?) {
        view?.show(items: items, changeSet: changeSet)
    }

}
