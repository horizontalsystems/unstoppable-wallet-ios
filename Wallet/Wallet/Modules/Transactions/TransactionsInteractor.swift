import RxSwift

class TransactionsInteractor {

    weak var delegate: ITransactionsInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var secondaryDisposeBag = DisposeBag()

    private let adapterManager: IAdapterManager
    private let exchangeRateManager: IExchangeRateManager

    init(adapterManager: IAdapterManager, exchangeRateManager: IExchangeRateManager) {
        self.adapterManager = adapterManager
        self.exchangeRateManager = exchangeRateManager
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func retrieveFilters() {
        adapterManager.subject
                .subscribe(onNext: { [weak self] in
                    self?.secondaryDisposeBag = DisposeBag()
                    self?.initialFetchAndSubscribe()
                })
                .disposed(by: disposeBag)

        initialFetchAndSubscribe()
    }

    private func initialFetchAndSubscribe() {
        let filters = adapterManager.adapters.map { adapter in
            TransactionFilter(adapterId: adapter.id, coinName: adapter.coin.name)
        }

        delegate?.didRetrieve(filters: filters)

        for adapter in adapterManager.adapters {
            adapter.transactionRecordsSubject
                    .subscribe(onNext: { [weak self] in
                        self?.retrieveTransactionItems(adapterId: nil)
                    })
                    .disposed(by: secondaryDisposeBag)
        }
    }

    func retrieveTransactionItems(adapterId: String?) {
        let rates = exchangeRateManager.exchangeRates
        var items = [TransactionRecordViewItem]()

        let filteredAdapters = adapterManager.adapters.filter { adapterId == nil || $0.id == adapterId }

        for adapter in filteredAdapters {
            for record in adapter.transactionRecords {
                let convertedValue = rates[adapter.coin.code].map { $0 * record.amount }

                let item = TransactionRecordViewItem(
                        transactionHash: record.transactionHash,
                        amount: CoinValue(coin: adapter.coin, value: record.amount),
                        currencyAmount: convertedValue.map { CurrencyValue(currency: DollarCurrency(), value: $0) },
                        from: record.from.first(where: { !$0.mine })?.address,
                        to: record.to.first(where: { !$0.mine })?.address,
                        incoming: record.amount > 0,
                        date: record.timestamp.map { Date(timeIntervalSince1970: Double($0)) },
                        status: record.status
                )

                items.append(item)
            }
        }

        delegate?.didRetrieve(items: items)
    }

}
