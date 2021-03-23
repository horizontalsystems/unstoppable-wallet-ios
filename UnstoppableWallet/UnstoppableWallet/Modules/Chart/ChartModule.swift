import Foundation
import XRatesKit
import CurrencyKit
import Chart
import CoinKit

struct ChartModule {

    enum LaunchMode {
        case partial(coinCode: String, coinTitle: String, coinType: CoinType)
        case coin(coin: Coin)

        var coinCode: String {
            switch self {
            case let .partial(coinCode, _, _):
                return coinCode
            case let .coin(coin):
                return coin.code
            }
        }

        var coinType: CoinType {
            switch self {
            case let .partial(_, _, coinType):
                return coinType
            case let .coin(coin):
                return coin.type
            }
        }

        var coinTitle: String {
            switch self {
            case let .partial(_, coinTitle, _):
                return coinTitle
            case let .coin(coin):
                return coin.title
            }
        }

        var coin: Coin? {
            if case let .coin(coin) = self {
                return coin
            }

            return  nil
        }
    }

}

protocol IChartView: class {
    func set(title: String)
    func set(favorite: Bool)

    func set(viewItem: ChartViewItem)

    func set(types: [String])
    func setSelectedType(at: Int?)

    func setSelectedState(hidden: Bool)
    func showSelectedPoint(viewItem: SelectedPointViewItem)
}

protocol IChartRouter {
    func open(link: String?)
    func openAlertSettings(coin: Coin)
}

protocol IChartViewDelegate {
    var currency: Currency { get }

    func onLoad()

    func onSelectType(at index: Int)

    func onTap(indicator: ChartIndicatorSet)
    func onTapLink()

    func onTapAlert()
    func onTapFavorite()
    func onTapUnfavorite()
}

protocol IChartInteractor {
    var defaultChartType: ChartType? { get set }
    var alertsOn: Bool { get }

    func chartInfo(coinType: CoinType, currencyCode: String, chartType: ChartType) -> ChartInfo?
    func subscribeToChartInfo(coinType: CoinType, currencyCode: String, chartType: ChartType)

    func marketInfo(coinType: CoinType, currencyCode: String) -> MarketInfo?
    func subscribeToMarketInfo(coinType: CoinType, currencyCode: String)
    func priceAlert(coin: Coin?) -> PriceAlert?
    func subscribeToAlertUpdates()

    func favorite(coinType: CoinType)
    func unfavorite(coinType: CoinType)
    func isFavorite(coinType: CoinType) -> Bool
}

protocol IChartInteractorDelegate: class {
    func didReceive(chartInfo: ChartInfo, coinType: CoinType)
    func didReceive(marketInfo: MarketInfo)
    func onChartInfoError(error: Error)
    func didUpdate(alerts: [PriceAlert])
    func updateFavorite()
}

protocol IChartRateFactory {
    func chartViewItem(chartDataStatus: DataStatus<ChartInfo>, marketInfoStatus: DataStatus<MarketInfo>, chartType: ChartType, coinCode: String, currency: Currency, selectedIndicator: ChartIndicatorSet, coin: Coin?, priceAlert: PriceAlert?, alertsOn: Bool) -> ChartViewItem
    func selectedPointViewItem(chartItem: ChartItem, type: ChartType, currency: Currency, macdSelected: Bool) -> SelectedPointViewItem?
}

enum MovementTrend {
    case neutral
    case down
    case up
}

struct ChartIndicatorSet: OptionSet, Hashable {
    static let none = ChartIndicatorSet(rawValue: 0)

    let rawValue: UInt8

    static let ema = ChartIndicatorSet(rawValue: 1 << 0)
    static let macd = ChartIndicatorSet(rawValue: 1 << 1)
    static let rsi = ChartIndicatorSet(rawValue: 1 << 2)

    static let all: [ChartIndicatorSet] = [.macd, .rsi, .ema]

    func toggle(indicator: ChartIndicatorSet) -> ChartIndicatorSet {
        ChartIndicatorSet(rawValue: ~rawValue & indicator.rawValue)
    }

    var hideVolumes: Bool {
        rawValue > 0
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
    let supply: String
    let maxSupply: Value
    let startDate: Value
    let website: Value
}

struct SelectedPointViewItem {
    let date: String
    let value: String?

    let rightSideMode: RightSideMode

    enum RightSideMode {
        case volume(value: String?)
        case macd(macdInfo: MacdInfo)
    }
}

struct MacdInfo {
    let macd: String?
    let signal: String?
    let histogram: String?
    let histogramDown: Bool?
}

struct ChartViewItem {
    let currentRate: String?

    let chartDataStatus: DataStatus<ChartDataViewItem>
    let marketInfoStatus: DataStatus<MarketInfoViewItem>

    let selectedIndicator: ChartIndicatorSet

    let priceAlertMode: ChartPriceAlertMode
}

enum ChartPriceAlertMode {
    case on
    case off
    case hidden
}

struct PriceIndicatorViewItem: CustomStringConvertible {
    enum Range {
        case day
        case year

        var description: String {
            switch self {
            case .day: return "chart.price_indicator_range.day".localized
            case .year: return "chart.price_indicator_range.year".localized
            }
        }

    }

    let low: String
    let high: String
    let range: Range
    let currentPercentage: CGFloat
}
