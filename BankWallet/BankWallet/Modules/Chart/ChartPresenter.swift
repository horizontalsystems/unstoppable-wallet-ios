import UIKit

class ChartPresenter {
    weak var view: IChartView?

    private let interactor: IChartInteractor
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

    private func updateButtons(rateStats: RateStatsData) {
        var enabledTypes = [ChartType]()
        ChartType.allCases.forEach { type in
            let enabled = (rateStats.stats[type.rawValue]?.values.count ?? 0) > 10
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
            interactor.setDefault(chartType: firstType)
        }
        view?.setChartType(tag: chartType.tag)
    }

}

extension ChartPresenter: IChartViewDelegate {

    func viewDidLoad() {
        view?.addTypeButtons(types: ChartType.allCases)

        view?.showSpinner()
        interactor.getRateStats(coinCode: coin.code, currencyCode: currency.code)

        view?.reloadAllModels()
    }

    func onSelect(type: ChartType) {
        guard chartType != type else {
            return
        }

        chartType = type
        interactor.setDefault(chartType: type)

        updateChart()
    }

    func chartTouchSelect(point: ChartPoint) {
        let currencyValue = CurrencyValue(currency: currency, value: point.value)
        view?.showSelectedPoint(timestamp: point.timestamp, value: currencyValue)
    }

}

extension ChartPresenter: IChartInteractorDelegate {

    func didReceive(chartData: ChartData, rate: Rate?) {
        self.chartData = chartData
        self.rate = rate

        view?.hideSpinner()
        updateButtons(rateStats: rateStats)
        updateChart()
    }

    func onError(_ error: Error) {
        view?.hideSpinner()
        view?.showError()
    }

}
