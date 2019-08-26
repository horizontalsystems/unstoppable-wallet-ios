import UIKit

class ChartPresenter {
    weak var view: IChartView?

    private let interactor: IChartInteractor
    private let factory: IChartRateFactory
    private let currency: Currency

    private var rateStatsData: RateStatsData?
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
        guard let rateStatsData = rateStatsData else {
            return
        }
        do {
            let viewItem = try factory.chartViewItem(type: chartType, rateStatsData: rateStatsData, rate: rate, currency: currency)
            view?.show(viewItem: viewItem)
        } catch {
            view?.show(error: error.localizedDescription)
        }
    }

}

extension ChartPresenter: IChartViewDelegate {

    func viewDidLoad() {
        view?.addTypeButtons(types: ChartType.allCases)
        view?.setChartType(tag: interactor.defaultChartType.tag)

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

    func didReceive(rateStats: RateStatsData, rate: Rate?) {
        self.rateStatsData = rateStats
        self.rate = rate

        view?.hideSpinner()
        updateChart()
    }

    func onError(_ error: Error) {
        view?.hideSpinner()
        view?.show(error: error.localizedDescription)
    }

}
