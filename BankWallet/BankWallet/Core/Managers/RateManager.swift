import Foundation
import RxSwift

class RateManager {
    private let disposeBag = DisposeBag()

    let subject = PublishSubject<Void>()

    private let storage: IRateStorage
    private let syncer: IRateSyncer
    private let walletManager: IWalletManager
    private let currencyManager: ICurrencyManager
    private var timer: IPeriodicTimer

    init(storage: IRateStorage, syncer: IRateSyncer, walletManager: IWalletManager, currencyManager: ICurrencyManager, reachabilityManager: IReachabilityManager, timer: IPeriodicTimer) {
        self.storage = storage
        self.syncer = syncer
        self.walletManager = walletManager
        self.currencyManager = currencyManager
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
        let coins = walletManager.wallets.map { $0.coinCode }
        let currencyCode = currencyManager.baseCurrency.code

        syncer.sync(coins: coins, currencyCode: currencyCode)
    }

}

extension RateManager: IRateManager {

    func rate(forCoin coinCode: CoinCode, currencyCode: String) -> Rate? {
        return storage.rate(forCoin: coinCode, currencyCode: currencyCode)
    }

}

extension RateManager: IPeriodicTimerDelegate {

    func onFire() {
        updateRates()
    }

}

extension RateManager: IRateSyncerDelegate {

    func didSync(coinCode: String, currencyCode: String, latestRate: LatestRate) {
        storage.save(latestRate: latestRate, coinCode: coinCode, currencyCode: currencyCode)
        subject.onNext(())
    }

}
