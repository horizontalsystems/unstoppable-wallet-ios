import Foundation
import RxSwift
import CurrencyKit
import HsToolKit
import CoinKit

class TransactionsInteractor {
    private let disposeBag = DisposeBag()
    private var statesDisposeBag = DisposeBag()
    private var lastBlockHeightsDisposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()
    private var transactionRecordsDisposeBag = DisposeBag()
    private let serialQueueScheduler = SerialDispatchQueueScheduler(qos: .utility)

    weak var delegate: ITransactionsInteractorDelegate?

    private let walletManager: IWalletManager
    private let currencyKit: CurrencyKit.Kit
    private let rateManager: IRateManager
    private let reachabilityManager: IReachabilityManager

    private var requestedTimestamps = [(Coin, Date)]()

    init(walletManager: IWalletManager, currencyKit: CurrencyKit.Kit, rateManager: IRateManager, reachabilityManager: IReachabilityManager) {
        self.walletManager = walletManager
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.reachabilityManager = reachabilityManager
    }

    private func onUpdateCoinsData() {
        transactionRecordsDisposeBag = DisposeBag()
        statesDisposeBag = DisposeBag()
        var walletsData = [(Wallet, LastBlockInfo?)]()
        var states = [Coin: AdapterState]()

        for activeWallet in walletManager.activeWallets {
            if let adapter = activeWallet.transactionAdapter {
                walletsData.append((activeWallet.wallet, adapter.lastBlockInfo))
                states[activeWallet.wallet.coin] = adapter.transactionState

                adapter.transactionRecordsObservable
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] records in
                            self?.delegate?.didUpdate(records: records, wallet: activeWallet.wallet)
                        })
                        .disposed(by: transactionRecordsDisposeBag)

                adapter.transactionStateUpdatedObservable
                        .subscribeOn(serialQueueScheduler)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] in
                            self?.delegate?.didUpdate(state: adapter.transactionState, wallet: activeWallet.wallet)
                        })
                        .disposed(by: statesDisposeBag)
            }
        }

        delegate?.onUpdate(walletsData: walletsData)
        delegate?.onUpdate(states: states)
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

//        adapterManager.adaptersReadyObservable
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { [weak self] in
//                    self?.onUpdateCoinsData()
//                })
//                .disposed(by: disposeBag)

        currencyKit.baseCurrencyUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.ratesDisposeBag = DisposeBag()
                    self?.requestedTimestamps = []
                    self?.delegate?.onUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)

        reachabilityManager.reachabilityObservable
                .subscribe(onNext: { [weak self] _ in
                    self?.onReachabilityChange()
                })
                .disposed(by: disposeBag)
    }

    func fetchLastBlockHeights() {
        lastBlockHeightsDisposeBag = DisposeBag()

        for activeWallet in walletManager.activeWallets {
            guard let adapter = activeWallet.transactionAdapter else {
                continue
            }

            adapter.lastBlockUpdatedObservable
                    .throttle(.seconds(3), latest: true, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        if let lastBlockInfo = adapter.lastBlockInfo {
                            self?.delegate?.onUpdate(lastBlockInfo: lastBlockInfo, wallet: activeWallet.wallet)
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

        var singles = [Single<(Wallet, [TransactionRecord])>]()

        for fetchData in fetchDataList {
            let activeWallet = walletManager.activeWallets.first(where: { $0.wallet == fetchData.wallet })
            let single: Single<(Wallet, [TransactionRecord])>

            if let activeWallet = activeWallet, let adapter = activeWallet.transactionAdapter {
                single = adapter.transactionsSingle(from: fetchData.from, limit: fetchData.limit)
                        .map { records -> (Wallet, [TransactionRecord]) in
                            (fetchData.wallet, records)
                        }
            } else {
                single = Single.just((fetchData.wallet, []))
            }

            singles.append(single)
        }

        Single.zip(singles)
                { tuples -> [Wallet: [TransactionRecord]] in
                    var recordsData = [Wallet: [TransactionRecord]]()

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

    func set(selectedWallets: [Wallet]) {
        delegate?.onUpdate(selectedCoins: selectedWallets)
    }

    func fetchRate(coin: Coin, date: Date) {
        guard !requestedTimestamps.contains(where: { $0 == coin && $1 == date }) else {
            return
        }

        requestedTimestamps.append((coin, date))

        let currency = currencyKit.baseCurrency

        rateManager.historicalRate(coinType: coin.type, currencyCode: currency.code, timestamp: date.timeIntervalSince1970)
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
