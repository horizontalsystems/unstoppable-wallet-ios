import Foundation

protocol IChartView: class {
    func showSpinner()
    func hideSpinner()

    func set(chartType: ChartType)
    func setChartTypeEnabled(tag: Int)

    func show(viewItem: ChartViewItem)

    func showSelectedPoint(chartType: ChartType, timestamp: TimeInterval, value: CurrencyValue)

    func showError()

    func reloadAllModels()
    func addTypeButtons(types: [ChartType])
}

protocol IChartViewDelegate {
    var coin: Coin { get }

    func viewDidLoad()

    func onSelect(type: ChartType)
    func chartTouchSelect(point: ChartPoint)
}

protocol IChartInteractor {
    var defaultChartType: ChartType { get set }

    func subscribeToChartStats()
    func subscribeToLatestRate(coinCode: CoinCode, currencyCode: String)
    func syncStats(coinCode: CoinCode, currencyCode: String)
}

protocol IChartInteractorDelegate: class {
    func didReceive(chartData: ChartData)
    func didReceive(rate: RateOld)
    func onError()
}

protocol IChartRateConverter {
    func convert(chartRateData: ChartRateData) -> [ChartPoint]
}

protocol IChartRateFactory {
    func chartViewItem(type: ChartType, chartData: ChartData, rate: RateOld?, currency: Currency) throws -> ChartViewItem
}
