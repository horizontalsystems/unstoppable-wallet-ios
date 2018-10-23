import RxSwift

class TransactionsInteractor {

    weak var delegate: ITransactionsInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var secondaryDisposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let exchangeRateManager: IExchangeRateManager

    init(walletManager: IWalletManager, exchangeRateManager: IExchangeRateManager) {
        self.walletManager = walletManager
        self.exchangeRateManager = exchangeRateManager
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func retrieveFilters() {
//        walletManager.subject
//                .subscribe(onNext: { [weak self] in
//                    self?.secondaryDisposeBag = DisposeBag()
//                    self?.initialFetchAndSubscribe()
//                })
//                .disposed(by: disposeBag)

        initialFetchAndSubscribe()
    }

    private func initialFetchAndSubscribe() {
        let filters = walletManager.wallets.map { $0.coin }

        delegate?.didRetrieve(filters: filters)

        for wallet in walletManager.wallets {
            wallet.adapter.transactionRecordsSubject
                    .subscribe(onNext: { [weak self] in
                        self?.retrieveTransactionItems(coin: nil)
                    })
                    .disposed(by: secondaryDisposeBag)
        }
    }

    func retrieveTransactionItems(coin: Coin?) {
        let rates = exchangeRateManager.exchangeRates
        var items = [TransactionRecordViewItem]()

        let filteredWallets = walletManager.wallets.filter { coin == nil || $0.coin == coin }

        for wallet in filteredWallets {
            for record in wallet.adapter.transactionRecords {
                let convertedValue = rates[wallet.coin].map { $0.value * record.amount }

                let item = TransactionRecordViewItem(
                        transactionHash: record.transactionHash,
                        amount: CoinValue(coin: wallet.coin, value: record.amount),
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
