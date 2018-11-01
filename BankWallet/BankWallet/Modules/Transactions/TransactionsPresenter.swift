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
        view?.set(title: "transactions.title")
        interactor.retrieveFilters()
    }

    func onTransactionItemClick(transaction: TransactionRecordViewItem) {
        router.openTransactionInfo(transaction: transaction)
    }

    func refresh() {
        interactor.refresh()
    }

    func onFilterSelect(coin: Coin?) {
        interactor.set(coin: coin)
    }

    var itemsCount: Int {
        return interactor.recordsCount
    }

    func item(forIndex index: Int) -> TransactionRecordViewItem {
        let record = interactor.record(forIndex: index)

        let convertedValue = record.rate == 0 ? nil : record.rate * record.amount

        var status: TransactionStatus = .processing

        if record.blockHeight != 0, let adapter = interactor.adapter(forCoin: record.coin), let lastBlockHeight = adapter.lastBlockHeight {
            let confirmations = lastBlockHeight - record.blockHeight + 1
            let threshold = adapter.confirmationsThreshold

            if confirmations >= threshold {
                status = .completed
            } else {
                status = .verifying(progress: Double(confirmations) / Double(threshold))
            }
        }

        return TransactionRecordViewItem(
                transactionHash: record.transactionHash,
                amount: CoinValue(coin: record.coin, value: record.amount),
                currencyAmount: convertedValue.map { CurrencyValue(currency: Currency(code: "USD", localeId: "en_US"), value: $0) },
                from: record.from.first(where: { !$0.mine })?.address,
                to: record.to.first(where: { !$0.mine })?.address,
                incoming: record.amount > 0,
                date: record.timestamp == 0 ? nil : Date(timeIntervalSince1970: Double(record.timestamp)),
                status: status
        )
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func didUpdateDataSource() {
        view?.reload()
    }

    func didRetrieve(filters: [Coin]) {
        var filterItems: [TransactionFilterItem] = filters.map {
            return TransactionFilterItem(coin: $0, name: "coin.\($0)")
        }
        filterItems.insert(TransactionFilterItem(coin: nil, name: "transactions.filter_all"), at: 0)
        view?.show(filters: filterItems)
    }

    func didRefresh() {
        view?.didRefresh()
    }

}
