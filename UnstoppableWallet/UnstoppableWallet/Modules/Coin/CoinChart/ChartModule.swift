import Foundation
import UIKit
import CurrencyKit
import Chart

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
    static let dominance = ChartIndicatorSet(rawValue: 1 << 3)

    static let all: [ChartIndicatorSet] = [.macd, .rsi, .ema]

    func toggle(indicator: ChartIndicatorSet) -> ChartIndicatorSet {
        ChartIndicatorSet(rawValue: ~rawValue & indicator.rawValue)
    }

    var hideVolumes: Bool {
        rawValue > 1
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

}

struct SelectedPointViewItem {
    let date: String
    let value: String?

    let rightSideMode: RightSideMode

    enum RightSideMode {
        case none
        case volume(value: String?)
        case macd(macdInfo: MacdInfo)
        case dominance(value: Decimal?)
    }
}

struct MacdInfo {
    let macd: String?
    let signal: String?
    let histogram: String?
    let histogramDown: Bool?
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
