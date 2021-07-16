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

    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let currencyKit: CurrencyKit.Kit
    private let rateManager: IRateManager
    private let reachabilityManager: IReachabilityManager

    private var requestedTimestamps = [(Coin, Date)]()

    init(walletManager: WalletManager, adapterManager: AdapterManager, currencyKit: CurrencyKit.Kit, rateManager: IRateManager, reachabilityManager: IReachabilityManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.reachabilityManager = reachabilityManager
    }

    private func onReachabilityChange() {
        if reachabilityManager.isReachable {
            delegate?.onConnectionRestore()
        }
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func initialFetch() {
        delegate?.onUpdate(wallets: walletManager.activeWallets)

        adapterManager.adaptersReadyObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self.flatMap { $0.delegate?.onUpdate(wallets: $0.walletManager.activeWallets) }
                })
                .disposed(by: disposeBag)

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

    func fetchLastBlockHeights(wallets: [TransactionWallet]) {
        lastBlockHeightsDisposeBag = DisposeBag()

        for wallet in wallets {
            print("fetching adapter for \(wallet.source.blockchain)")
            guard let adapter = adapterManager.transactionsAdapter(for: wallet) else {
                continue
            }
            print("adapter for \(wallet.source.blockchain): \(adapter)")

            adapter.lastBlockUpdatedObservable
                    .throttle(.seconds(3), latest: true, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        if let lastBlockInfo = adapter.lastBlockInfo {
                            self?.delegate?.onUpdate(lastBlockInfo: lastBlockInfo, wallet: wallet)
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

        var singles = [Single<(TransactionWallet, [TransactionRecord])>]()

        for fetchData in fetchDataList {
            let wallet = fetchData.wallet
            let single: Single<(TransactionWallet, [TransactionRecord])>

            if let adapter = adapterManager.transactionsAdapter(for: wallet) {
                single = adapter.transactionsSingle(from: fetchData.from, coin: fetchData.wallet.coin, limit: fetchData.limit)
                        .map { records -> (TransactionWallet, [TransactionRecord]) in
                            (fetchData.wallet, records)
                        }
            } else {
                single = Single.just((fetchData.wallet, []))
            }

            singles.append(single)
        }

        Single.zip(singles)
                { tuples -> [TransactionWallet: [TransactionRecord]] in
                    var recordsData = [TransactionWallet: [TransactionRecord]]()

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

    func observe(wallets: [TransactionWallet]) {
        transactionRecordsDisposeBag = DisposeBag()
        statesDisposeBag = DisposeBag()

        var lastBlockInfos = [(TransactionWallet, LastBlockInfo?)]()
        var states = [TransactionWallet: AdapterState]()

        for wallet in wallets {
            if let adapter = adapterManager.transactionsAdapter(for: wallet) {
                lastBlockInfos.append((wallet, adapter.lastBlockInfo))
                states[wallet] = adapter.transactionState

                adapter.transactionsObservable(coin: wallet.coin)
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] records in
                            self?.delegate?.didUpdate(records: records, wallet: wallet)
                        })
                        .disposed(by: transactionRecordsDisposeBag)

                adapter.transactionStateUpdatedObservable
                        .subscribeOn(serialQueueScheduler)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] in
                            self?.delegate?.didUpdate(state: adapter.transactionState, wallet: wallet)
                        })
                        .disposed(by: statesDisposeBag)
            }
        }

        delegate?.onUpdate(lastBlockInfos: lastBlockInfos)
        delegate?.onUpdate(states: states)
    }

}
