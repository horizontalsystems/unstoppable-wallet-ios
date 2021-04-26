import UIKit
import RxSwift
import Chart
import LanguageKit
import XRatesKit

protocol IMetricChartConfiguration {
    var title: String { get }
    var description: String? { get }
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
        let timestamp: TimeInterval
    }

}
