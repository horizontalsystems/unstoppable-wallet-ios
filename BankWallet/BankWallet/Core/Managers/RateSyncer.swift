import RxSwift

class RateSyncer {
    private let refreshIntervalInMinutes = 5

    private let disposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let walletManager: IWalletManager
    private let currencyManager: ICurrencyManager
    private let reachabilityManager: IReachabilityManager

    init(rateManager: IRateManager, walletManager: IWalletManager, currencyManager: ICurrencyManager, reachabilityManager: IReachabilityManager) {
        self.rateManager = rateManager
        self.walletManager = walletManager
        self.currencyManager = currencyManager
        self.reachabilityManager = reachabilityManager

        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        let timer = Observable<Int>.timer(.seconds(0), period: .seconds(refreshIntervalInMinutes * 60), scheduler: scheduler).map { _ in () }

        Observable.merge(walletManager.walletsUpdatedSignal, currencyManager.baseCurrencyUpdatedSignal, reachabilityManager.reachabilitySignal, timer)
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.syncLatestRates()
                })
                .disposed(by: disposeBag)
    }

    private func syncLatestRates() {
        guard reachabilityManager.isReachable else {
            return
        }

        var coinCodes = Set<CoinCode>()
        for wallet in walletManager.wallets {
            coinCodes.insert(wallet.coin.code)
        }

        guard coinCodes.count > 0 else {
            return
        }

        rateManager.refreshLatestRates(coinCodes: Array(coinCodes), currencyCode: currencyManager.baseCurrency.code)
    }

}
