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

    func onTransactionItemClick(transaction: TransactionRecordViewItem, coin: Coin, txHash: String) {
        router.showTransactionInfo(transaction: transaction, coin: coin, txHash: txHash)
    }

    func refresh() {
        print("on refresh")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.view?.didRefresh()
        })
    }

    func onFilterSelect(coin: Coin?) {
        interactor.retrieveTransactionItems(coin: coin)
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func didRetrieve(filters: [Coin]) {
        var filterItems: [TransactionFilterItem] = filters.map {
            return TransactionFilterItem(coin: $0, name: $0.localized.uppercased())
        }
        filterItems.insert(TransactionFilterItem(coin: nil, name: "transactions.filter_all".localized.uppercased()), at: 0)
        view?.show(filters: filterItems)
        interactor.retrieveTransactionItems(coin: nil)
    }

    func didRetrieve(items: [TransactionRecordViewItem]) {
        view?.show(items: items)
    }

}
