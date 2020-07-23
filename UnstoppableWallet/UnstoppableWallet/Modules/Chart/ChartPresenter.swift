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

    private var chartDataStatus: ChartDataStatus<ChartInfo> = .loading
    private var marketInfoStatus: ChartDataStatus<MarketInfo> = .loading

    let coin: Coin
    let currency: Currency

    private var chartType: ChartType

    private var selectedIndicators = ChartIndicatorSet()

    private var alert: PriceAlert?

    init(router: IChartRouter, interactor: IChartInteractor, factory: IChartRateFactory, coin: Coin, currency: Currency) {
        self.router = router
        self.interactor = interactor
        self.factory = factory
        self.coin = coin
        self.currency = currency

        chartType = interactor.defaultChartType ?? .day
    }

    private func updateChart() {
        let viewItem = factory.chartViewItem(
                chartDataStatus: chartDataStatus,
                marketInfoStatus: marketInfoStatus,
                chartType: chartType,
                coinCode: coin.code,
                currency: currency,
                selectedIndicator: selectedIndicators,
                priceAlert: alert)

        view?.set(viewItem: viewItem)
    }

    private func fetchInfo() {
        chartDataStatus = ChartDataStatus(data: interactor.chartInfo(coinCode: coin.code, currencyCode: currency.code, chartType: chartType))
        interactor.subscribeToChartInfo(coinCode: coin.code, currencyCode: currency.code, chartType: chartType)

        marketInfoStatus = ChartDataStatus(data: interactor.marketInfo(coinCode: coin.code, currencyCode: currency.code))
        interactor.subscribeToMarketInfo(coinCode: coin.code, currencyCode: currency.code)

        interactor.subscribeToAlertUpdates()

        alert = interactor.priceAlert(coin: coin)

        updateChart()
    }

}

extension ChartPresenter: IChartViewDelegate {

    func onLoad() {
        view?.set(title: coin.title)

        view?.set(types: types.map { $0.title })
        view?.setSelectedType(at: types.firstIndex(of: chartType))

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
        router.open(link: CoinInfoMap.data[coin.code]?.website)
    }

    func onTapAlert() {
        router.openAlertSettings(coin: coin)
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

    func onChartInfoError() {
        chartDataStatus = .failed
        updateChart()
    }

    func didUpdate(alerts: [PriceAlert]) {
        alert = alerts.first {
            $0.coin == coin
        }

        updateChart()
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
