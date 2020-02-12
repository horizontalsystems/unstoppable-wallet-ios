import RxSwift

class BackgroundPriceAlertManager {
    private let disposeBag = DisposeBag()

    private let rateManager: IRateManager
//    private let currencyManager: ICurrencyManager
    private let priceAlertStorage: IPriceAlertStorage
    private let priceAlertHandler: IPriceAlertHandler
    private let debugBackgroundLogger: IDebugLogger?

    init(rateManager: IRateManager, priceAlertStorage: IPriceAlertStorage, priceAlertHandler: IPriceAlertHandler, debugBackgroundLogger: IDebugLogger?) {
        self.rateManager = rateManager
//        self.currencyManager = currencyManager
        self.priceAlertStorage = priceAlertStorage
        self.priceAlertHandler = priceAlertHandler
        self.debugBackgroundLogger = debugBackgroundLogger
    }

}

extension BackgroundPriceAlertManager: IBackgroundPriceAlertManager {

    func didEnterBackground() {
//        let alerts = priceAlertStorage.activePriceAlerts
//        let currency = currencyManager.baseCurrency
//
//        alerts.forEach { alert in
//            if let rate = rateStorage.latestRate(coinCode: alert.coin.code, currencyCode: currency.code) {
//                alert.lastRate = rate.value
//            }
//        }
//
//        priceAlertStorage.save(priceAlerts: alerts)
    }

    func fetchRates(onComplete: @escaping (Bool) -> ()) {
        debugBackgroundLogger?.add(log: "did fetch rates")
//        rateManager.syncLatestRatesSingle()
//                .subscribe(onSuccess: { [weak self] latestRatesData in
//                    self?.priceAlertHandler.handleAlerts(with: latestRatesData)
//                    onComplete(true)
//                }, onError: { error in
//                    onComplete(false)
//                })
//                .disposed(by: disposeBag)
    }

}
