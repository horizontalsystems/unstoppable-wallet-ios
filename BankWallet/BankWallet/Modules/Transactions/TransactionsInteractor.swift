import Foundation
import RxSwift

class TransactionsInteractor {
    private let disposeBag = DisposeBag()
    private var lastBlockHeightsDisposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()
    private var transactionRecordsDisposeBag = DisposeBag()

    weak var delegate: ITransactionsInteractorDelegate?

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let currencyManager: ICurrencyManager
    private let rateManager: IRateManager
    private let reachabilityManager: IReachabilityManager

    private var requestedTimestamps = [(Coin, Date)]()

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, currencyManager: ICurrencyManager, rateManager: IRateManager, reachabilityManager: IReachabilityManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.currencyManager = currencyManager
        self.rateManager = rateManager
        self.reachabilityManager = reachabilityManager

        adapterManager.adapterCreationObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] wallet in
                    self?.onUpdateCoinsData()
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateCoinsData() {
        transactionRecordsDisposeBag = DisposeBag()
        var coinsData = [(Coin, Int, Int?)]()

        for wallet in walletManager.wallets {
            if let adapter = adapterManager.adapter(for: wallet) {
                coinsData.append((wallet.coin, adapter.confirmationsThreshold, adapter.lastBlockHeight))

                adapter.transactionRecordsObservable
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] records in
                            self?.delegate?.didUpdate(records: records, coin: wallet.coin)
                        })
                        .disposed(by: transactionRecordsDisposeBag)
            }
        }

        delegate?.onUpdate(coinsData: coinsData)
    }

    private func onReachabilityChange() {
        if reachabilityManager.isReachable {
            delegate?.onConnectionRestore()
        }
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func initialFetch() {
        onUpdateCoinsData()

        walletManager.walletsUpdatedSignal
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
                    self?.requestedTimestamps = []
                    self?.delegate?.onUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)

        reachabilityManager.reachabilitySignal
                .subscribe(onNext: { [weak self] in
                    self?.onReachabilityChange()
                })
                .disposed(by: disposeBag)
    }

    func fetchLastBlockHeights() {
        lastBlockHeightsDisposeBag = DisposeBag()

        for wallet in walletManager.wallets {
            guard let adapter = adapterManager.adapter(for: wallet) else {
                continue
            }

            adapter.lastBlockHeightUpdatedObservable
                    .throttle(.seconds(3), latest: true, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        if let lastBlockHeight = adapter.lastBlockHeight {
                            self?.delegate?.onUpdate(lastBlockHeight: lastBlockHeight, coin: wallet.coin)
                        }
                    })
                    .disposed(by: lastBlockHeightsDisposeBag)
        }
    }

    func fetchRecords(fetchDataList: [FetchData], initial: Bool) {
        guard !fetchDataList.isEmpty else {
            delegate?.didFetch(recordsData: [:], initial: initial)
            return
        }

        var singles = [Single<(Coin, [TransactionRecord])>]()

        for fetchData in fetchDataList {
            let wallet = walletManager.wallets.first(where: { $0.coin == fetchData.coin })
            let single: Single<(Coin, [TransactionRecord])>

            if let wallet = wallet, let adapter = adapterManager.adapter(for: wallet) {
                single = adapter.transactionsSingle(from: fetchData.from, limit: fetchData.limit)
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
                    self?.delegate?.didFetch(recordsData: recordsData, initial: initial)
                })
                .disposed(by: disposeBag)
    }

    func set(selectedCoins: [Coin]) {
        let allCoins = walletManager.wallets.map { $0.coin }
        delegate?.onUpdate(selectedCoins: selectedCoins.isEmpty ? allCoins : selectedCoins)
    }

    func fetchRate(coin: Coin, date: Date) {
        guard !requestedTimestamps.contains(where: { $0 == coin && $1 == date }) else {
            return
        }

        requestedTimestamps.append((coin, date))

        let currency = currencyManager.baseCurrency

        rateManager.timestampRateValueObservable(coinCode: coin.code, currencyCode: currency.code, date: date)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] rateValue in
                    self?.delegate?.didFetch(rateValue: rateValue, coin: coin, currency: currency, date: date)
                }, onError: { [weak self] _ in
                    self?.requestedTimestamps.removeAll { $0 == coin && $1 == date }
                })
                .disposed(by: ratesDisposeBag)
    }

}
