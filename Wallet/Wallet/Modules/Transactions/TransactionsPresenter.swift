import Foundation
import WalletKit

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

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func didRetrieve(items: [TransactionRecordViewItem], changeSet: CollectionChangeSet?) {
        view?.show(items: items, changeSet: changeSet)
    }

}
