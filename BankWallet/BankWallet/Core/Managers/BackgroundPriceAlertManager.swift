import RxSwift

class BackgroundPriceAlertManager {
    private let disposeBag = DisposeBag()
    private let rateManager: IRateManager
    private let currencyManager: ICurrencyManager
    private let rateStorage: IRateStorage
    private let priceAlertStorage: IPriceAlertStorage
    private let priceAlertHandler: IPriceAlertHandler

    init(rateManager: IRateManager, currencyManager: ICurrencyManager, rateStorage: IRateStorage, priceAlertStorage: IPriceAlertStorage, priceAlertHandler: IPriceAlertHandler) {
        self.rateManager = rateManager
        self.currencyManager = currencyManager
        self.rateStorage = rateStorage
        self.priceAlertStorage = priceAlertStorage
        self.priceAlertHandler = priceAlertHandler
    }

}

extension BackgroundPriceAlertManager : IBackgroundPriceAlertManager {

    func updateAlerts() {
        let alerts = priceAlertStorage.priceAlerts
        let currency = currencyManager.baseCurrency
        alerts.forEach { alert in
            if alert.state != .off, let rate = rateStorage.latestRate(coinCode: alert.coin.code, currencyCode: currency.code) {
                alert.lastRate = rate.value
                priceAlertStorage.save(priceAlert: alert)
            }
        }
    }

    func fetchRates(completion: ((Bool) -> ())?) {
        rateManager.syncLatestRatesSingle().subscribe(onSuccess: { [weak self] latestRatesData in
            self?.priceAlertHandler.handleAlerts(with: latestRatesData)
            completion?(true)
        }, onError: { error in
            completion?(false)
        }).disposed(by: disposeBag)
    }

}
