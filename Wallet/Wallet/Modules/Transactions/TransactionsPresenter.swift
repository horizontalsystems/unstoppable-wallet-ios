import RealmSwift

class TransactionsPresenter {

    weak var view: ITransactionsView?
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter

    private var results: Results<TransactionRecord>

    private var resultsToken: NotificationToken?

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter) {
        self.interactor = interactor
        self.router = router

        results = interactor.realmResults(forCoin: nil)

        resultsToken = results.observe { [weak self] _ in
            self?.view?.reload()
        }
    }

    deinit {
        resultsToken?.invalidate()
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        interactor.retrieveFilters()
    }

    func onTransactionItemClick(transaction: TransactionRecordViewItem) {
        router.openTransactionInfo(transaction: transaction)
    }

    func refresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.view?.didRefresh()
        })
    }

    func onFilterSelect(coin: Coin?) {
        resultsToken?.invalidate()
        results = interactor.realmResults(forCoin: coin)

        resultsToken = results.observe { [weak self] _ in
            self?.view?.reload()
        }

        view?.reload()
    }

    var itemsCount: Int {
        return results.count
    }

    func item(forIndex index: Int) -> TransactionRecordViewItem {
        let record = results[index]

        let convertedValue = record.rate == 0 ? nil : record.rate * record.amount

        return TransactionRecordViewItem(
                transactionHash: record.transactionHash,
                amount: CoinValue(coin: record.coin, value: record.amount),
                currencyAmount: convertedValue.map { CurrencyValue(currency: DollarCurrency(), value: $0) },
                from: record.from.first(where: { !$0.mine })?.address,
                to: record.to.first(where: { !$0.mine })?.address,
                incoming: record.amount > 0,
                date: record.timestamp == 0 ? nil : Date(timeIntervalSince1970: Double(record.timestamp)),
                status: record.status,
                verifyProgress: record.verifyProgress
        )
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func didRetrieve(filters: [Coin]) {
        var filterItems: [TransactionFilterItem] = filters.map {
            return TransactionFilterItem(coin: $0, name: $0.localized.uppercased())
        }
        filterItems.insert(TransactionFilterItem(coin: nil, name: "transactions.filter_all".localized.uppercased()), at: 0)
        view?.show(filters: filterItems)
    }

}
