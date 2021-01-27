import UIKit
import XRatesKit
import CurrencyKit
import Chart

class ChartPresenter {
    private let types = ChartType.allCases

    weak var view: IChartView?

    private var router: IChartRouter
    private var interactor: IChartInteractor
    private let factory: IChartRateFactory

    private var chartDataStatus: DataStatus<ChartInfo> = .loading
    private var marketInfoStatus: DataStatus<MarketInfo> = .loading

    let launchMode: ChartModule.LaunchMode
    let currency: Currency

    private var chartType: ChartType

    private var selectedIndicators = ChartIndicatorSet()

    private var alert: PriceAlert?

    init(router: IChartRouter, interactor: IChartInteractor, factory: IChartRateFactory, launchMode: ChartModule.LaunchMode, currency: Currency) {
        self.router = router
        self.interactor = interactor
        self.factory = factory
        self.launchMode = launchMode
        self.currency = currency

        chartType = interactor.defaultChartType ?? .today
    }

    private func updateChart() {
        let viewItem = factory.chartViewItem(
                chartDataStatus: chartDataStatus,
                marketInfoStatus: marketInfoStatus,
                chartType: chartType,
                coinCode: launchMode.coinCode,
                currency: currency,
                selectedIndicator: selectedIndicators,
                coin: launchMode.coin,
                priceAlert: alert,
                alertsOn: interactor.alertsOn)

        view?.set(viewItem: viewItem)
    }

    private func fetchInfo() {
        chartDataStatus = DataStatus(data: interactor.chartInfo(coinCode: launchMode.coinCode, currencyCode: currency.code, chartType: chartType))
        interactor.subscribeToChartInfo(coinCode: launchMode.coinCode, currencyCode: currency.code, chartType: chartType)

        marketInfoStatus = DataStatus(data: interactor.marketInfo(coinCode: launchMode.coinCode, currencyCode: currency.code))
        interactor.subscribeToMarketInfo(coinCode: launchMode.coinCode, currencyCode: currency.code)

        interactor.subscribeToAlertUpdates()

        alert = interactor.priceAlert(coin: launchMode.coin)

        updateChart()
    }

}

extension ChartPresenter: IChartViewDelegate {

    func onLoad() {
        view?.set(title: launchMode.coinTitle)

        view?.set(types: types.map { $0.title })
        view?.setSelectedType(at: types.firstIndex(of: chartType))

        updateFavorite()

        fetchInfo()
    }

    func onSelectType(at index: Int) {
        guard types.count > index else {
            return
        }
        chartType = types[index]
        interactor.defaultChartType = chartType

        fetchInfo()
    }

    func onTap(indicator: ChartIndicatorSet) {
        selectedIndicators = selectedIndicators.toggle(indicator: indicator)

        updateChart()
    }

    func onTapLink() {
        router.open(link: CoinInfoMap.data[launchMode.coinCode]?.website)
    }

    func onTapAlert() {
        guard let coin = launchMode.coin else {
            return
        }

        router.openAlertSettings(coin: coin)
    }

    func onTapFavorite() {
        interactor.favorite(coinCode: launchMode.coinCode)
    }

    func onTapUnfavorite() {
        interactor.unfavorite(coinCode: launchMode.coinCode)
    }

}

extension ChartPresenter: IChartInteractorDelegate {

    func didReceive(chartInfo: ChartInfo, coinCode: CoinCode) {
        guard coinCode == coinCode else {
            return
        }
        chartDataStatus = .completed(chartInfo)
        updateChart()
    }

    func didReceive(marketInfo: MarketInfo) {
        marketInfoStatus = .completed(marketInfo)
        updateChart()
    }

    func onChartInfoError(error: Error) {
        chartDataStatus = .failed(error)
        updateChart()
    }

    func didUpdate(alerts: [PriceAlert]) {
        alert = alerts.first {
            $0.coin.code == launchMode.coinCode
        }

        updateChart()
    }

    func updateFavorite() {
        view?.set(favorite: interactor.isFavorite(coinCode: launchMode.coinCode))
    }

}

extension ChartPresenter: IChartViewTouchDelegate {

    func touchDown() {
        view?.setSelectedState(hidden: false)
    }

    func select(item: ChartItem) {
        guard let viewItem = factory.selectedPointViewItem(chartItem: item, type: chartType, currency: currency, macdSelected: selectedIndicators.contains(.macd)) else {
            return
        }

        view?.showSelectedPoint(viewItem: viewItem)
    }

    func touchUp() {
        view?.setSelectedState(hidden: true)
    }

}
