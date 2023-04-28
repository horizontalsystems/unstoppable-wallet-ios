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

extension MarketCategoryMarketCapFetcher: IMetricChartFetcher {

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

    var intervals: [HsTimePeriod] {
        [.day1, .week1, .month1]
    }

    func fetch(interval: HsTimePeriod) async throws -> MetricChartModule.ItemData {
        let points = try await marketKit.coinCategoryMarketCapChart(category: category, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)

        let items = points.map { point -> MetricChartModule.Item in
            MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }

}
