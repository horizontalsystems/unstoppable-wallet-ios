import Chart
import Combine
import MarketKit
import UIKit

protocol IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType { get }
    var intervals: [HsPeriodType] { get }
    var needUpdateIntervals: AnyPublisher<Void, Never> { get }
    var needUpdatePublisher: AnyPublisher<Void, Never> { get }
    func fetch(interval: HsPeriodType) async throws -> MetricChartModule.ItemData
}

extension IMetricChartFetcher {
    var intervals: [HsPeriodType] {
        [HsTimePeriod.day1, .week1, .week2, .month1, .month3, .month6, .year1].periodTypes
    }

    var needUpdateIntervals: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    var needUpdatePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }
}

enum MetricChartModule {
    enum ValueType {
        case percent
        case counter
        case compactCoinValue(Coin)
        case compactCurrencyValue(Currency)
        case currencyValue(Currency)
    }

    struct ItemData {
        let items: [Item]
        let indicators: [String: [Decimal]]
        let type: ItemType

        init(items: [Item], indicators: [String: [Decimal]] = [:], type: ItemType) {
            self.items = items
            self.indicators = indicators
            self.type = type
        }
    }

    enum ItemType {
        case regular
        case aggregated(value: Decimal?)
    }

    struct Item {
        let value: Decimal
        let timestamp: TimeInterval

        init(value: Decimal, timestamp: TimeInterval) {
            self.value = value
            self.timestamp = timestamp
        }
    }

    struct OverriddenValue {
        let value: String
        let description: String?
    }

    enum FetchError: Error {
        case onlyHsTimePeriod
    }
}

extension HsPeriodType {
    var title: String {
        switch self {
        case let .byPeriod(interval): return interval.title
        default: return "chart.time_duration.all".localized
        }
    }

    var byStartTime: Bool {
        switch self {
        case .byStartTime: return true
        default: return false
        }
    }
}
