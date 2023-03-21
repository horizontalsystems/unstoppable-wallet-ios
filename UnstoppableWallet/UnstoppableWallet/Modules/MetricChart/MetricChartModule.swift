import UIKit
import RxSwift
import Chart
import LanguageKit
import MarketKit
import CurrencyKit

protocol IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType { get }
    var intervals: [HsTimePeriod] { get }
    var needUpdateObservable: Observable<()> { get }
    func fetchSingle(interval: HsTimePeriod) -> Single<MetricChartModule.ItemData>
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

    struct ItemData {
        let items: [Item]
        let type: ItemType
    }

    enum ItemType {
        case regular
        case aggregated(value: Decimal?)
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

    struct OverriddenValue {
        let value: String
        let description: String?
    }

}
