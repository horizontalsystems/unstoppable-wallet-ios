import UIKit

class ChartPresenter {
    weak var view: IChartView?

    private var interactor: IChartInteractor
    private let factory: IChartRateFactory
    private let currency: Currency

    private var chartData: ChartData?
    private var rate: Rate?

    let coin: Coin

    private var chartType: ChartType

    init(interactor: IChartInteractor, factory: IChartRateFactory, coin: Coin, currency: Currency) {
        self.interactor = interactor
        self.factory = factory
        self.coin = coin
        self.currency = currency

        chartType = interactor.defaultChartType
    }

    private func updateChart() {
        guard let rateStatsData = chartData else {
            return
        }
        do {
            let viewItem = try factory.chartViewItem(type: chartType, chartData: rateStatsData, rate: rate, currency: currency)
            view?.show(viewItem: viewItem)
        } catch {
            view?.showError()
        }
    }

    private func updateButtons(chartData: ChartData) {
        var enabledTypes = [ChartType]()
        ChartType.allCases.forEach { type in
            let enabled = (chartData.stats[type]?.count ?? 0) > 10
            if enabled {
                enabledTypes.append(type)
                view?.setChartTypeEnabled(tag: type.tag)
            }
        }
        if !enabledTypes.contains(chartType) {
            guard let firstType = enabledTypes.first else {
                view?.showError()
                return
            }
            chartType = firstType
            interactor.defaultChartType = firstType
        }
        view?.set(chartType: chartType)
    }

}

extension ChartPresenter: IChartViewDelegate {

    func viewDidLoad() {
        view?.showSpinner()

        interactor.subscribeToChartStats()
        interactor.subscribeToLatestRate(coinCode: coin.code, currencyCode: currency.code)
        interactor.syncStats(coinCode: coin.code, currencyCode: currency.code)

        view?.addTypeButtons(types: ChartType.allCases)

        view?.reloadAllModels()
    }

    func onSelect(type: ChartType) {
        guard chartType != type else {
            return
        }

        chartType = type
        interactor.defaultChartType = type

        updateChart()
    }

    func chartTouchSelect(point: ChartPoint) {
        let currencyValue = CurrencyValue(currency: currency, value: point.value)
        view?.showSelectedPoint(chartType: chartType, timestamp: point.timestamp, value: currencyValue)
    }

}

extension ChartPresenter: IChartInteractorDelegate {

    func didReceive(chartData: ChartData) {
        guard chartData.coinCode == coin.code else {
            return
        }

        self.chartData = chartData

        view?.hideSpinner()
        updateButtons(chartData: chartData)
        updateChart()
    }

    func didReceive(rate: Rate) {
        self.rate = rate
        updateChart()
    }

    func onError() {
        view?.hideSpinner()
        view?.showError()
    }

}
