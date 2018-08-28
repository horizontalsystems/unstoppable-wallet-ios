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
        interactor.retrieveFilters()
    }

    func onTransactionItemClick(transaction: TransactionRecordViewItem, coinCode: String, txHash: String) {
        router.showTransactionInfo(transaction: transaction, coinCode: coinCode, txHash: txHash)
    }

    func refresh() {
        print("on refresh")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.view?.didRefresh()
        })
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func didRetrieve(filters: [TransactionFilter]) {
        view?.show(filters: filters)
        interactor.retrieveTransactionItems(adapterId: nil)
    }

    func didRetrieve(items: [TransactionRecordViewItem]) {
        view?.show(items: items)
    }

}
