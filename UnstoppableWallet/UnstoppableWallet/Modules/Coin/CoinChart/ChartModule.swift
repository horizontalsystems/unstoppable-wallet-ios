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

enum MovementTrend {
    case neutral
    case down
    case up
}

struct ChartIndicatorSet: OptionSet, Hashable {
    static let none = ChartIndicatorSet([])

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
        case none
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
