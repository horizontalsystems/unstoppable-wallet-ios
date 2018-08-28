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

    func onFilterSelect(adapterId: String?) {
        interactor.retrieveTransactionItems(adapterId: adapterId)
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func didRetrieve(filters: [TransactionFilter]) {
        var filterItems: [TransactionFilterItem] = filters.map {
            return TransactionFilterItem(adapterId: $0.adapterId, name: "transactions.filter_\($0.coinName)".localized.uppercased())
        }
        filterItems.insert(TransactionFilterItem(adapterId: nil, name: "transactions.filter_all".localized.uppercased()), at: 0)
        view?.show(filters: filterItems)
        interactor.retrieveTransactionItems(adapterId: nil)
    }

    func didRetrieve(items: [TransactionRecordViewItem]) {
        view?.show(items: items)
    }

}
