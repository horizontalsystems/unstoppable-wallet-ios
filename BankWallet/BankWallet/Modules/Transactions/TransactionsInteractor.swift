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

    private var requestedTimestamps = [Coin: [Double]]()

    init(adapterManager: IAdapterManager, currencyManager: ICurrencyManager, rateManager: IRateManager) {
        self.adapterManager = adapterManager
        self.currencyManager = currencyManager
        self.rateManager = rateManager
    }

    private func onUpdateCoinsData() {
        var coinsData = [(Coin, Int, Int?)]()

        for adapter in adapterManager.adapters {
            coinsData.append((adapter.coin, adapter.confirmationsThreshold, adapter.lastBlockHeight))
        }

        delegate?.onUpdate(coinsData: coinsData)

        transactionRecordsDisposeBag = DisposeBag()

        adapterManager.adapters.forEach { adapter in
            adapter.transactionRecordsSubject
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] records in
                        self?.delegate?.didUpdate(records: records, coin: adapter.coin)
                    })
                    .disposed(by: transactionRecordsDisposeBag)
        }
    }

    private func onUpdateLastBlockHeight(adapter: IAdapter) {
        if let lastBlockHeight = adapter.lastBlockHeight {
            delegate?.onUpdate(lastBlockHeight: lastBlockHeight, coin: adapter.coin)
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

        var singles = [Single<(Coin, [TransactionRecord])>]()

        for fetchData in fetchDataList {
            let adapter = adapterManager.adapters.first(where: { $0.coin == fetchData.coin })
            let single: Single<(Coin, [TransactionRecord])>

            if let adapter = adapter {
                single = adapter.transactionsSingle(hashFrom: fetchData.hashFrom, limit: fetchData.limit)
                        .map { records -> (Coin, [TransactionRecord]) in
                            (fetchData.coin, records)
                        }
            } else {
                single = Single.just((fetchData.coin, []))
            }

            singles.append(single)
        }

        Single.zip(singles)
                { tuples -> [Coin: [TransactionRecord]] in
                    var recordsData = [Coin: [TransactionRecord]]()

                    for (coin, records) in tuples {
                        recordsData[coin] = records
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

    func set(selectedCoins: [Coin]) {
        let allCoins = adapterManager.adapters.map { $0.coin }
        delegate?.onUpdate(selectedCoins: selectedCoins.isEmpty ? allCoins : selectedCoins)
    }

    func fetchRates(timestampsData: [Coin: [Double]]) {
        let currency = currencyManager.baseCurrency

        for (coin, timestamps) in timestampsData {
            for timestamp in timestamps {
                if let timestamps = requestedTimestamps[coin], timestamps.contains(timestamp) {
                    continue
                }

                if requestedTimestamps[coin] == nil {
                    requestedTimestamps[coin] = [Double]()
                }
                requestedTimestamps[coin]?.append(timestamp)

                rateManager.timestampRateValueObservable(coinCode: coin.code, currencyCode: currency.code, timestamp: timestamp)
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] rateValue in
//                            print("did fetch: \(coinCode) -- \(currency.code) -- \(timestamp) -- \(rateValue)")
                            self?.delegate?.didFetch(rateValue: rateValue, coin: coin, currency: currency, timestamp: timestamp)
                        })
                        .disposed(by: ratesDisposeBag)
            }
        }
    }

}
