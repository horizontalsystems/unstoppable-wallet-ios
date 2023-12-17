import Chart
import Foundation
import MarketKit

class MarketCategoryMarketCapFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let category: String

    init(currencyManager: CurrencyManager, marketKit: MarketKit.Kit, category: String) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.category = category
    }
}

extension MarketCategoryMarketCapFetcher: IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyManager.baseCurrency)
    }

    var intervals: [HsPeriodType] {
        [HsTimePeriod.day1, .week1, .month1].periodTypes
    }

    func fetch(interval: HsPeriodType) async throws -> MetricChartModule.ItemData {
        guard case let .byPeriod(interval) = interval else {
            throw MetricChartModule.FetchError.onlyHsTimePeriod
        }

        let points = try await marketKit.coinCategoryMarketCapChart(category: category, currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)

        let items = points.map { point -> MetricChartModule.Item in
            MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }
}
