import UIKit
import RxSwift
import XRatesKit
import CoinKit

class ChartInteractor {
    weak var delegate: IChartInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var chartsDisposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let favoritesManager: IFavoritesManager
    private let chartTypeStorage: IChartTypeStorage
    private let currentDateProvider: ICurrentDateProvider
    private let priceAlertManager: IPriceAlertManager
    private let localStorage: ILocalStorage

    init(rateManager: IRateManager, favoritesManager: IFavoritesManager, chartTypeStorage: IChartTypeStorage, currentDateProvider: ICurrentDateProvider, priceAlertManager: IPriceAlertManager, localStorage: ILocalStorage) {
        self.rateManager = rateManager
        self.favoritesManager = favoritesManager
        self.chartTypeStorage = chartTypeStorage
        self.currentDateProvider = currentDateProvider
        self.priceAlertManager = priceAlertManager
        self.localStorage = localStorage
    }

}

extension ChartInteractor: IChartInteractor {

    var defaultChartType: ChartType? {
        get {
            chartTypeStorage.chartType
        }
        set {
            chartTypeStorage.chartType = newValue
        }
    }

    var alertsOn: Bool {
        localStorage.pushNotificationsOn
    }

    func chartInfo(coinType: CoinType, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        rateManager.chartInfo(coinType: coinType, currencyCode: currencyCode, chartType: chartType)
    }

    func subscribeToChartInfo(coinType: CoinType, currencyCode: String, chartType: ChartType) {
        chartsDisposeBag = DisposeBag()

        rateManager.chartInfoObservable(coinType: coinType, currencyCode: currencyCode, chartType: chartType)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] chartInfo in
                    self?.delegate?.didReceive(chartInfo: chartInfo, coinType: coinType)
                }, onError: { [weak self] error in
                    self?.delegate?.onChartInfoError(error: error)
                })
                .disposed(by: chartsDisposeBag)
    }

    func marketInfo(coinType: CoinType, currencyCode: String) -> MarketInfo? {
        rateManager.marketInfo(coinType: coinType, currencyCode: currencyCode)
    }

    func subscribeToMarketInfo(coinType: CoinType, currencyCode: String) {
        rateManager.marketInfoObservable(coinType: coinType, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfo in
                    self?.delegate?.didReceive(marketInfo: marketInfo)
                })
                .disposed(by: disposeBag)
    }

    func priceAlert(coin: Coin?) -> PriceAlert? {
        guard let coin = coin else {
            return nil
        }

        return priceAlertManager.priceAlert(coin: coin)
    }

    func subscribeToAlertUpdates() {
        priceAlertManager.updateObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] alerts in
                    self?.delegate?.didUpdate(alerts: alerts)
                })
                .disposed(by: disposeBag)
    }

    func favorite(coinType: CoinType) {
        favoritesManager.add(coinType: coinType)

        delegate?.updateFavorite()
    }

    func unfavorite(coinType: CoinType) {
        favoritesManager.remove(coinType: coinType)

        delegate?.updateFavorite()
    }

    func isFavorite(coinType: CoinType) -> Bool {
        favoritesManager.isFavorite(coinType: coinType)
    }

}
