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
                .subscribe(onNext: { [weak self] wallets in
                    self?.syncLatestRates()
                })
                .disposed(by: disposeBag)
    }

    private func syncLatestRates() {
        if reachabilityManager.isReachable {
            var coinCodes = Set<CoinCode>()
            for wallet in walletManager.wallets {
                coinCodes.insert(wallet.coin.code)
            }
            rateManager.refreshLatestRates(coinCodes: Array(coinCodes), currencyCode: currencyManager.baseCurrency.code)
        }
    }

}
