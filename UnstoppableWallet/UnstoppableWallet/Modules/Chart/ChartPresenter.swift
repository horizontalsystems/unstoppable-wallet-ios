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

    let coinCode: String
    let coinTitle: String
    let currency: Currency

    private var chartType: ChartType

    private var selectedIndicators = ChartIndicatorSet()

    private var alert: PriceAlert?

    init(router: IChartRouter, interactor: IChartInteractor, factory: IChartRateFactory, coinCode: String, coinTitle: String, currency: Currency) {
        self.router = router
        self.interactor = interactor
        self.factory = factory
        self.coinCode = coinCode
        self.coinTitle = coinTitle
        self.currency = currency

        chartType = interactor.defaultChartType ?? .day
    }

    private func updateChart() {
        let viewItem = factory.chartViewItem(
                chartDataStatus: chartDataStatus,
                marketInfoStatus: marketInfoStatus,
                chartType: chartType,
                coinCode: coinCode,
                currency: currency,
                selectedIndicator: selectedIndicators,
                priceAlert: alert,
                alertsOn: interactor.alertsOn)

        view?.set(viewItem: viewItem)
    }

    private func fetchInfo() {
        chartDataStatus = DataStatus(data: interactor.chartInfo(coinCode: coinCode, currencyCode: currency.code, chartType: chartType))
        interactor.subscribeToChartInfo(coinCode: coinCode, currencyCode: currency.code, chartType: chartType)

        marketInfoStatus = DataStatus(data: interactor.marketInfo(coinCode: coinCode, currencyCode: currency.code))
        interactor.subscribeToMarketInfo(coinCode: coinCode, currencyCode: currency.code)

        interactor.subscribeToAlertUpdates()

        alert = interactor.priceAlert(coinCode: coinCode)

        updateChart()
    }

}

extension ChartPresenter: IChartViewDelegate {

    func onLoad() {
        view?.set(title: coinTitle)

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
        router.open(link: CoinInfoMap.data[coinCode]?.website)
    }

    func onTapAlert() {
        guard let coin = interactor.coin(code: coinCode) else {
            return
        }

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
        chartDataStatus = .failed(nil)
        updateChart()
    }

    func didUpdate(alerts: [PriceAlert]) {
        alert = alerts.first {
            $0.coin.code == coinCode
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
