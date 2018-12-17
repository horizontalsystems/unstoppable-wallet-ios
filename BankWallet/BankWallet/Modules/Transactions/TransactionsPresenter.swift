import Foundation

class TransactionsPresenter {

    weak var view: ITransactionsView?
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter
    private let factory: ITransactionViewItemFactory

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter, factory: ITransactionViewItemFactory) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        view?.set(title: "transactions.title")
        interactor.retrieveFilters()
    }

    func onTransactionItemClick(transaction: TransactionViewItem) {
        router.openTransactionInfo(transactionHash: transaction.transactionHash)
    }

    func onFilterSelect(coinCode: CoinCode?) {
        interactor.set(coinCode: coinCode)
    }

    var itemsCount: Int {
        return interactor.recordsCount
    }

    func item(forIndex index: Int) -> TransactionViewItem {
        let record = interactor.record(forIndex: index)
        return factory.item(fromRecord: record)
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func didUpdateDataSource() {
        view?.reload()
    }

    func didRetrieve(filters: [CoinCode]) {
        var filterItems: [TransactionFilterItem] = filters.map {
            return TransactionFilterItem(coinCode: $0, name: "coin.\($0)")
        }
        filterItems.insert(TransactionFilterItem(coinCode: nil, name: "transactions.filter_all"), at: 0)
        view?.show(filters: filterItems)
    }

}
