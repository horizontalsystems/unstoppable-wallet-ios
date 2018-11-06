import Foundation
import RxSwift

class RateManager {
    private let disposeBag = DisposeBag()

    let subject = PublishSubject<Void>()

    private let storage: IRateStorage
    private let syncer: IRateSyncer
    private let walletManager: IWalletManager
    private let currencyManager: ICurrencyManager
    private let reachabilityManager: IReachabilityManager
    private var timer: IPeriodicTimer

    init(storage: IRateStorage, syncer: IRateSyncer, walletManager: IWalletManager, currencyManager: ICurrencyManager, reachabilityManager: IReachabilityManager, timer: IPeriodicTimer) {
        self.storage = storage
        self.syncer = syncer
        self.walletManager = walletManager
        self.currencyManager = currencyManager
        self.reachabilityManager = reachabilityManager
        self.timer = timer

        self.timer.delegate = self

        walletManager.walletsSubject
                .subscribe(onNext: { [weak self] _ in
                    self?.updateRates()
                })
                .disposed(by: disposeBag)

        currencyManager.subject
                .subscribe(onNext: { [weak self] _ in
                    self?.updateRates()
                })
                .disposed(by: disposeBag)

        reachabilityManager.subject
                .subscribe(onNext: { [weak self] connected in
                    if connected {
                        self?.updateRates()
                    }
                })
                .disposed(by: disposeBag)
    }

    private func updateRates() {
        let coins = walletManager.wallets.map { $0.coin }
        let currencyCode = currencyManager.baseCurrency.code

        syncer.sync(coins: coins, currencyCode: currencyCode)
    }

}

extension RateManager: IRateManager {

    func rate(forCoin coin: Coin, currencyCode: String) -> Rate? {
        return storage.rate(forCoin: coin, currencyCode: currencyCode)
    }

}

extension RateManager: IPeriodicTimerDelegate {

    func onFire() {
        updateRates()
    }

}

extension RateManager: IRateSyncerDelegate {

    func didSync(coin: String, currencyCode: String, value: Double) {
        storage.save(value: value, coin: coin, currencyCode: currencyCode)
        subject.onNext(())
    }

}
