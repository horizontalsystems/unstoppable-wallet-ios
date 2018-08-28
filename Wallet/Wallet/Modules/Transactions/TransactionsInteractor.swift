import Foundation
import RxSwift

class TransactionsInteractor {

    weak var delegate: ITransactionsInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var secondaryDisposeBag = DisposeBag()

    private let adapterManager: AdapterManager
    private let exchangeRateManager: ExchangeRateManager

    init(adapterManager: AdapterManager, exchangeRateManager: ExchangeRateManager) {
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
            let latestBlockHeight = adapter.latestBlockHeight

            for record in adapter.transactionRecords {
                let confirmations = record.blockHeight.map { latestBlockHeight - $0 + 1 } ?? 0
                let convertedValue = rates[adapter.coin.code].map { $0 * record.amount }

                let item = TransactionRecordViewItem(
                        transactionHash: record.transactionHash,
                        amount: CoinValue(coin: adapter.coin, value: record.amount),
                        currencyAmount: convertedValue.map { CurrencyValue(currency: DollarCurrency(), value: $0) },
                        fee: CoinValue(coin: adapter.coin, value: record.fee),
                        from: record.from.first,
                        to: record.to.first,
                        incoming: record.amount > 0,
                        blockHeight: record.blockHeight,
                        date: record.timestamp.map { Date(timeIntervalSince1970: Double($0)) },
                        status: confirmations > 0 ? .success : .pending,
                        confirmations: confirmations
                )

                items.append(item)
            }
        }

        delegate?.didRetrieve(items: items)
    }

}
