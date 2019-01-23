import RxSwift

class RateSyncer {
    private let refreshIntervalInMinutes: Double = 3

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
        let timer = Observable<Int>.timer(0, period: refreshIntervalInMinutes * 60, scheduler: scheduler).map { _ in () }

        Observable.merge(walletManager.walletsUpdatedSignal, currencyManager.baseCurrencyUpdatedSignal, reachabilityManager.reachabilitySignal, timer)
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.sync()
                })
                .disposed(by: disposeBag)
    }

    private func sync() {
        if reachabilityManager.isReachable {
            rateManager.refreshLatestRates(coinCodes: walletManager.wallets.map { $0.coinCode }, currencyCode: currencyManager.baseCurrency.code)
        }
    }

}
