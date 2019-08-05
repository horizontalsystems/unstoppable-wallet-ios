import RxSwift

class RateSyncer {
    private let refreshIntervalInMinutes = 5

    private let disposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let adapterManager: IAdapterManager
    private let currencyManager: ICurrencyManager
    private let reachabilityManager: IReachabilityManager

    init(rateManager: IRateManager, adapterManager: IAdapterManager, currencyManager: ICurrencyManager, reachabilityManager: IReachabilityManager) {
        self.rateManager = rateManager
        self.adapterManager = adapterManager
        self.currencyManager = currencyManager
        self.reachabilityManager = reachabilityManager

        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        let timer = Observable<Int>.timer(.seconds(0), period: .seconds(refreshIntervalInMinutes * 60), scheduler: scheduler).map { _ in () }

        Observable.merge(adapterManager.adaptersUpdatedSignal, currencyManager.baseCurrencyUpdatedSignal, reachabilityManager.reachabilitySignal, timer)
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.syncLatestRates()
                })
                .disposed(by: disposeBag)
    }

    private func syncLatestRates() {
        if reachabilityManager.isReachable {
            var coinCodes = Set<CoinCode>()
            for adapter in adapterManager.adapters {
                coinCodes.insert(adapter.wallet.coin.code)
                if let feeCoinCode = adapter.feeCoinCode {
                    coinCodes.insert(feeCoinCode)
                }
            }
            rateManager.refreshLatestRates(coinCodes: Array(coinCodes), currencyCode: currencyManager.baseCurrency.code)
        }
    }

}
