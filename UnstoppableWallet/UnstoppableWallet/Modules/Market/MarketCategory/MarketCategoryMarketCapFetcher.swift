import RxSwift
import Foundation
import MarketKit
import CurrencyKit
import Chart

class MarketCategoryMarketCapFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let category: String

    init(currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit, category: String) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.category = category
    }

}

extension MarketCategoryMarketCapFetcher: IMetricChartConfiguration {
    var title: String { category }
    var description: String? { nil }
    var poweredBy: String? { "HorizontalSystems API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

}

extension MarketCategoryMarketCapFetcher: IMetricChartFetcher {

    var intervals: [HsTimePeriod] {
        [.day1, .week1, .month1]
    }

    func fetchSingle(interval: HsTimePeriod) -> RxSwift.Single<MetricChartModule.ItemData> {
        marketKit
                .coinCategoryMarketCapChartSingle(category: category, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                .map { points in
                    let items = points.map { point -> MetricChartModule.Item in
                        MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
                    }

                    return MetricChartModule.ItemData(items: items, type: .regular)
                }
    }

}
