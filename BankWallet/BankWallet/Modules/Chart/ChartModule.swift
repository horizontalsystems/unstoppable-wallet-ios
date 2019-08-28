import Foundation

protocol IChartView: class {
    func showSpinner()
    func hideSpinner()

    func setChartType(tag: Int)
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
    var defaultChartType: ChartType { get }
    func setDefault(chartType: ChartType)

    func getRateStats(coinCode: String, currencyCode: String)
}

protocol IChartInteractorDelegate: class {
    func didReceive(chartData: ChartData, rate: Rate?)
    func onError(_ error: Error)
}

protocol IChartRateConverter {
    func convert(chartRateData: ChartRateData) -> [ChartPoint]
}

protocol IChartRateFactory {
    func chartViewItem(type: ChartType, chartData: ChartData, rate: Rate?, currency: Currency) throws -> ChartViewItem
}
