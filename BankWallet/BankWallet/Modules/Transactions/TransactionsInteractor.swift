import RxSwift

class TransactionsInteractor {
    private let disposeBag = DisposeBag()
    private var lastBlockHeightsDisposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()
    private var transactionRecordsDisposeBag = DisposeBag()

    weak var delegate: ITransactionsInteractorDelegate?

    private let adapterManager: IAdapterManager
    private let currencyManager: ICurrencyManager
    private let rateManager: IRateManager

    private var requestedTimestamps = [CoinCode: [Double]]()

    init(adapterManager: IAdapterManager, currencyManager: ICurrencyManager, rateManager: IRateManager) {
        self.adapterManager = adapterManager
        self.currencyManager = currencyManager
        self.rateManager = rateManager
    }

    private func onUpdateCoinsData() {
        var coinsData = [(CoinCode, Int, Int?)]()

        for adapter in adapterManager.adapters {
            coinsData.append((adapter.coin.code, adapter.confirmationsThreshold, adapter.lastBlockHeight))
        }

        delegate?.onUpdate(coinsData: coinsData)

        transactionRecordsDisposeBag = DisposeBag()

        adapterManager.adapters.forEach { adapter in
            adapter.transactionRecordsSubject
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] records in
                        self?.delegate?.didUpdate(records: records, coinCode: adapter.coin.code)
                    })
                    .disposed(by: transactionRecordsDisposeBag)
        }
    }

    private func onUpdateLastBlockHeight(adapter: IAdapter) {
        if let lastBlockHeight = adapter.lastBlockHeight {
            delegate?.onUpdate(lastBlockHeight: lastBlockHeight, coinCode: adapter.coin.code)
        }
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func initialFetch() {
        onUpdateCoinsData()

        adapterManager.adaptersUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateCoinsData()
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.ratesDisposeBag = DisposeBag()
                    self?.requestedTimestamps = [:]
                    self?.delegate?.onUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)
    }

    func fetchLastBlockHeights() {
        lastBlockHeightsDisposeBag = DisposeBag()

        adapterManager.adapters.forEach { adapter in
            adapter.lastBlockHeightUpdatedSignal
                    .throttle(3, latest: true, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.onUpdateLastBlockHeight(adapter: adapter)
                    })
                    .disposed(by: lastBlockHeightsDisposeBag)
        }
    }

    func fetchRecords(fetchDataList: [FetchData]) {
        guard !fetchDataList.isEmpty else {
            delegate?.didFetch(recordsData: [:])
            return
        }

        var singles = [Single<(CoinCode, [TransactionRecord])>]()

        for fetchData in fetchDataList {
            let adapter = adapterManager.adapters.first(where: { $0.coin.code == fetchData.coinCode })
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
                    var recordsData = [CoinCode: [TransactionRecord]]()

                    for (coinCode, records) in tuples {
                        recordsData[coinCode] = records
                    }

                    return recordsData
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] recordsData in
                    self?.delegate?.didFetch(recordsData: recordsData)
                })
                .disposed(by: disposeBag)
    }

    func set(selectedCoinCodes: [CoinCode]) {
        let allCoinCodes = adapterManager.adapters.map { $0.coin.code }
        delegate?.onUpdate(selectedCoinCodes: selectedCoinCodes.isEmpty ? allCoinCodes : selectedCoinCodes)
    }

    func fetchRates(timestampsData: [CoinCode: [Double]]) {
        let currency = currencyManager.baseCurrency

        for (coinCode, timestamps) in timestampsData {
            for timestamp in timestamps {
                if let timestamps = requestedTimestamps[coinCode], timestamps.contains(timestamp) {
                    continue
                }

                if requestedTimestamps[coinCode] == nil {
                    requestedTimestamps[coinCode] = [Double]()
                }
                requestedTimestamps[coinCode]?.append(timestamp)

                rateManager.timestampRateValueObservable(coinCode: coinCode, currencyCode: currency.code, timestamp: timestamp)
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] rateValue in
//                            print("did fetch: \(coinCode) -- \(currency.code) -- \(timestamp) -- \(rateValue)")
                            self?.delegate?.didFetch(rateValue: rateValue, coinCode: coinCode, currency: currency, timestamp: timestamp)
                        })
                        .disposed(by: ratesDisposeBag)
            }
        }
    }

}
