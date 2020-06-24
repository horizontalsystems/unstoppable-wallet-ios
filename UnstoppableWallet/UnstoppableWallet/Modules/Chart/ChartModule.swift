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

    func onTap(indicator: ChartIndicatorSet)
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
    func chartViewItem(chartDataStatus: ChartDataStatus<ChartInfo>, marketInfoStatus: ChartDataStatus<MarketInfo>, chartType: ChartType, coinCode: String, currency: Currency, selectedIndicator: ChartIndicatorSet) -> ChartViewItem
    func selectedPointViewItem(chartPoint: ChartPoint, type: ChartType, currency: Currency) -> SelectedPointViewItem
}

enum MovementTrend {
    case neutral
    case down
    case up
}

struct ChartIndicatorSet: OptionSet, Hashable {
    let rawValue: UInt8

    static let ema = ChartIndicatorSet(rawValue: 1 << 0)
    static let macd = ChartIndicatorSet(rawValue: 1 << 1)
    static let rsi = ChartIndicatorSet(rawValue: 1 << 2)

    static let all: [ChartIndicatorSet] = [.macd, .rsi, .ema]

    func toggle(indicator: ChartIndicatorSet) -> ChartIndicatorSet {
        let oldEmaValue: UInt8 = self.rawValue % 2
        let newEmaValue: UInt8 = indicator.rawValue % 2

        guard newEmaValue == 0 else {
            return  ChartIndicatorSet(rawValue: self.rawValue ^ 1)
        }

        let resultValue = ~self.rawValue & indicator.rawValue + oldEmaValue
        return ChartIndicatorSet(rawValue: resultValue)
    }

    var showVolumes: Bool {
        self.rawValue > 1
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

}

struct ChartDataViewItem {
    let chartData: ChartData

    let chartTrend: MovementTrend
    let chartDiff: Decimal?

    let trends: [ChartIndicatorSet: MovementTrend]

    let minValue: String?
    let maxValue: String?

    let timeline: [ChartTimelineItem]
}

struct MarketInfoViewItem {

    struct Value {
        let value: String?
        let accent: Bool
    }

    let marketCap: Value
    let volume: Value
    let supply: String?
    let maxSupply: Value
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

    let selectedIndicator: ChartIndicatorSet
}
