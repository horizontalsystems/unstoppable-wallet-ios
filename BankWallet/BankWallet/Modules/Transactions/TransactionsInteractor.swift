import RxSwift

class TransactionsInteractor {
    private let disposeBag = DisposeBag()
    private var lastBlockHeightsDisposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()
    private var transactionRecordsDisposeBag = DisposeBag()

    weak var delegate: ITransactionsInteractorDelegate?

    private let walletManager: IWalletManager
    private let currencyManager: ICurrencyManager
    private let rateManager: IRateManager

    init(walletManager: IWalletManager, currencyManager: ICurrencyManager, rateManager: IRateManager) {
        self.walletManager = walletManager
        self.currencyManager = currencyManager
        self.rateManager = rateManager
    }

    private func onUpdateCoinCodes(selectedCoinCodes: [CoinCode] = []) {
        let allCoinCodes = walletManager.wallets.map { $0.coinCode }
        delegate?.onUpdate(coinCodes: allCoinCodes)

        transactionRecordsDisposeBag = DisposeBag()

        walletManager.wallets.forEach { wallet in
            wallet.adapter.transactionRecordsSubject
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] records in
                        self?.delegate?.didUpdate(records: records, coinCode: wallet.coinCode)
                    })
                    .disposed(by: transactionRecordsDisposeBag)
        }
    }

    private func onUpdateLastBlockHeight(wallet: Wallet) {
        if let lastBlockHeight = wallet.adapter.lastBlockHeight {
            delegate?.onUpdate(lastBlockHeight: lastBlockHeight, coinCode: wallet.coinCode)
        }
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func initialFetch() {
        onUpdateCoinCodes()

        walletManager.walletsUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateCoinCodes()
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.ratesDisposeBag = DisposeBag()
                    self?.delegate?.onUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)
    }

    func fetchLastBlockHeights() {
        lastBlockHeightsDisposeBag = DisposeBag()

        walletManager.wallets.forEach { wallet in
            onUpdateLastBlockHeight(wallet: wallet)
            delegate?.onUpdate(threshold: wallet.adapter.confirmationsThreshold, coinCode: wallet.coinCode)

            wallet.adapter.lastBlockHeightUpdatedSignal
                    .throttle(3, latest: true, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.onUpdateLastBlockHeight(wallet: wallet)
                    })
                    .disposed(by: lastBlockHeightsDisposeBag)
        }
    }

    func fetchRecords(fetchDataList: [FetchData]) {
        guard !fetchDataList.isEmpty else {
            delegate?.didFetch(records: [:])
            return
        }

        var singles = [Single<(CoinCode, [TransactionRecord])>]()

        for fetchData in fetchDataList {
            let adapter = walletManager.wallets.first(where: { $0.coinCode == fetchData.coinCode })?.adapter
            let single: Single<(CoinCode, [TransactionRecord])>

            if let adapter = adapter {
                single = adapter.transactionsSingle(hashFrom: fetchData.hashFrom, limit: fetchData.limit)
                        .map { records -> (CoinCode, [TransactionRecord]) in
                            (fetchData.coinCode, records)
                        }
            } else {
                single = Single.just((fetchData.coinCode, []))
            }

            singles.append(single)
        }

        Single.zip(singles)
                { tuples -> [CoinCode: [TransactionRecord]] in
                    var result = [CoinCode: [TransactionRecord]]()

                    for (coinCode, records) in tuples {
                        result[coinCode] = records
                    }

                    return result
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] records in
                    self?.delegate?.didFetch(records: records)
                })
                .disposed(by: disposeBag)
    }

    func set(selectedCoinCodes: [CoinCode]) {
        let allCoinCodes = walletManager.wallets.map { $0.coinCode }
        delegate?.onUpdate(selectedCoinCodes: selectedCoinCodes.isEmpty ? allCoinCodes : selectedCoinCodes)
    }

    func fetchRates(timestamps: [CoinCode: [Double]]) {
        let currency = currencyManager.baseCurrency

        for (coinCode, timestamps) in timestamps {
            for timestamp in timestamps {
                rateManager.timestampRateValueObservable(coinCode: coinCode, currencyCode: currency.code, timestamp: timestamp)
                        .subscribe(onNext: { rateValue in
                            self.delegate?.didFetch(rateValue: rateValue, coinCode: coinCode, currency: currency, timestamp: timestamp)
                        })
                        .disposed(by: ratesDisposeBag)
            }
        }
    }

}
