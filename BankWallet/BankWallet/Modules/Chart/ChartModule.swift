import Foundation
import XRatesKit
import CurrencyKit

protocol IChartView: class {
    func showSpinner()
    func hideSpinner()

    func set(chartType: ChartType)

    func show(chartViewItem: ChartInfoViewItem)
    func show(marketInfoViewItem: MarketInfoViewItem)

    func showSelectedPoint(chartType: ChartType, timestamp: TimeInterval, value: CurrencyValue, volume: CurrencyValue?)

    func showError()

    func reloadAllModels()
    func set(types: [ChartType])
}

protocol IChartViewDelegate {
    var coin: Coin { get }
    var currency: Currency { get }

    func viewDidLoad()

    func onSelect(type: ChartType)
    func chartTouchSelect(timestamp: TimeInterval, value: Decimal, volume: Decimal?)
}

protocol IChartInteractor {
    var defaultChartType: ChartType? { get set }

    func chartInfo(coinCode: CoinCode, currencyCode: String, chartType: ChartType) -> ChartInfo?
    func subscribeToChartInfo(coinCode: CoinCode, currencyCode: String, chartType: ChartType)

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func subscribeToMarketInfo(coinCode: CoinCode, currencyCode: String)
}

protocol IChartInteractorDelegate: class {
    func didReceive(chartInfo: ChartInfo, coinCode: CoinCode)
    func didReceive(marketInfo: MarketInfo)
    func onError()
}

protocol IChartRateFactory {
    func chartViewItem(type: ChartType, chartInfo: ChartInfo, currency: Currency) throws -> ChartInfoViewItem
    func marketInfoViewItem(marketInfo: MarketInfo, coin: Coin, currency: Currency) -> MarketInfoViewItem
}
