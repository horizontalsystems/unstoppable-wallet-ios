import Foundation
import XRatesKit
import CurrencyKit
import Chart

protocol IChartView: class {
    func set(title: String)

    func set(viewItem: ChartViewItem)

    func set(types: [String])
    func setSelectedType(at: Int?)

    func setSelectedState(hidden: Bool)
    func showSelectedPoint(viewItem: SelectedPointViewItem)
}

protocol IChartViewDelegate {
    var currency: Currency { get }

    func onLoad()

    func onSelectType(at index: Int)

    func onTapEmaIndicator()
    func onTap(indicator: ChartIndicatorMode)
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
    func onChartInfoError()
}

protocol IChartRateFactory {
    func chartViewItem(chartDataStatus: ChartDataStatus<ChartInfo>, marketInfoStatus: ChartDataStatus<MarketInfo>, chartType: ChartType, coinCode: String, currency: Currency, showEma: Bool, selectedIndicator: ChartIndicatorMode) -> ChartViewItem
    func selectedPointViewItem(chartPoint: ChartPoint, type: ChartType, currency: Currency) -> SelectedPointViewItem
}

enum MovementTrend {
    case neutral
    case down
    case up
}

enum ChartIndicatorMode {
    case macd
    case rsi
    case none
}

struct ChartDataViewItem {
    let chartData: ChartData

    let chartTrend: MovementTrend
    let chartDiff: Decimal?

    let emaTrend: MovementTrend
    let macdTrend: MovementTrend
    let rsiTrend: MovementTrend

    let minValue: String?
    let maxValue: String?

    let timeline: [ChartTimelineItem]
}

struct MarketInfoViewItem {
    let marketCap: String?
    let volume: String?
    let supply: String?
    let maxSupply: String?
}

struct SelectedPointViewItem {
    let date: String
    let value: String?
    let volume: String?
}

struct ChartViewItem {
    let currentRate: String?

    let chartDataStatus: ChartDataStatus<ChartDataViewItem>
    let marketInfoStatus: ChartDataStatus<MarketInfoViewItem>

    let showEma: Bool
    let selectedIndicator: ChartIndicatorMode
}
