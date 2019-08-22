import Foundation

protocol IChartView: class {
    func bind(currentRateValue: CurrencyValue)
    func bind(diff: Decimal?)
    func bind(type: ChartType, chartPoints: [ChartPoint], animated: Bool)
    func bind(marketCapValue: CurrencyValue?, postfix: String?)
    func bind(type: ChartType, lowValue: CurrencyValue?)
    func bind(type: ChartType, highValue: CurrencyValue?)

    func showSelectedData(timestamp: TimeInterval, value: CurrencyValue)
    func showProgress()
    func show(error: String)

    func reloadAllModels()

    func addTypeButtons(types: [ChartType])
    func setButtonSelected(tag: Int)
}

protocol IChartViewDelegate {
    var coin: Coin { get }

    func viewDidLoad()

    func didSelect(type: ChartType)
    func chartTap(point: ChartPoint)
}

protocol IChartInteractor {
    var defaultChartType: ChartType { get }
    func set(chartType: ChartType)

    func currentRate(coinCode: CoinCode, currencyCode: String) -> Rate?
    func getRates(coinCode: String, currencyCode: String, chartType: ChartType)
    func getMarketCap()
}

protocol IChartInteractorDelegate: class {
    func didReceive(chartData: ChartRateData)
    func didReceive(marketCapData: MarketCapData)
    func onChartError(_ error: Error)
    func onMarketCapError(_ error: Error)
}

protocol IChartRateConverter {
    func convert(chartRateData: ChartRateData) -> [ChartPoint]
}
