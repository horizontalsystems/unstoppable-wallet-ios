import RxSwift
import Foundation
import MarketKit
import Chart

class MarketCategoryMarketCapFetcher {
    private let marketKit: MarketKit.Kit
    private let category: String

    init(marketKit: MarketKit.Kit, category: String) {
        self.marketKit = marketKit
        self.category = category
    }

}

extension MarketCategoryMarketCapFetcher: IMetricChartConfiguration {
    var title: String { category }
    var description: String? { nil }
    var poweredBy: String { "HorizontalSystems API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue
    }

}

extension MarketCategoryMarketCapFetcher: IMetricChartFetcher {

    var intervals: [HsTimePeriod] {
        [.day1, .week1, .month1]
    }

    func fetchSingle(currencyCode: String, interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        marketKit
                .coinCategoryMarketCapChartSingle(category: category, currencyCode: currencyCode, timePeriod: interval)
                .map { points in
                    points.map { point -> MetricChartModule.Item in
                        MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
                    }
                }
    }

}
