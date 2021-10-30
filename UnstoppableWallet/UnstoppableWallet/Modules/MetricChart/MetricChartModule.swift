import UIKit
import RxSwift
import Chart
import LanguageKit
import MarketKit

protocol IMetricChartConfiguration {
    var title: String { get }
    var description: String? { get }
    var poweredBy: String { get }
    var valueType: MetricChartModule.ValueType { get }
}

protocol IMetricChartFetcher {
    func fetchSingle(currencyCode: String, timePeriod: TimePeriod) -> Single<[MetricChartModule.Item]>
}

class MetricChartModule {

    enum ValueType {
        case percent
        case compactCurrencyValue
        case currencyValue
    }

    struct Item {
        let value: Decimal
        let indicators: [ChartIndicatorName: Decimal]?
        let timestamp: TimeInterval

        init(value: Decimal, indicators: [ChartIndicatorName: Decimal]? = nil, timestamp: TimeInterval) {
            self.value = value
            self.indicators = indicators
            self.timestamp = timestamp
        }

    }

}
