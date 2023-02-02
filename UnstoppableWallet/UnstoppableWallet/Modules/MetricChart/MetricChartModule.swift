import UIKit
import RxSwift
import Chart
import LanguageKit
import MarketKit
import CurrencyKit

protocol IMetricChartConfiguration {
    var title: String { get }
    var description: String? { get }
    var poweredBy: String? { get }
    var valueType: MetricChartModule.ValueType { get }
}

protocol IMetricChartFetcher {
    var intervals: [HsTimePeriod] { get }
    var needUpdateObservable: Observable<()> { get }
    func fetchSingle(interval: HsTimePeriod) -> Single<[MetricChartModule.Item]>
}

extension IMetricChartFetcher {

    var intervals: [HsTimePeriod] {
        [.day1, .week1, .week2, .month1, .month3, .month6, .year1]
    }

    var needUpdateObservable: Observable<()> {
        Observable.just(())
    }

}

class MetricChartModule {

    enum ValueType {
        case percent
        case counter
        case compactCoinValue(Coin)
        case compactCurrencyValue(Currency)
        case currencyValue(Currency)
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
