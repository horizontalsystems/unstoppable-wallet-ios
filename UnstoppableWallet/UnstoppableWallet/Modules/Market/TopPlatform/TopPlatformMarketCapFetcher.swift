import MarketKit

class TopPlatformMarketCapFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let topPlatform: TopPlatform

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, topPlatform: TopPlatform) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.topPlatform = topPlatform
    }

}

extension TopPlatformMarketCapFetcher: IMetricChartFetcher {

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyManager.baseCurrency)
    }

    var intervals: [HsTimePeriod] {
        [.day1, .week1, .month1]
    }

    func fetch(interval: HsTimePeriod) async throws -> MetricChartModule.ItemData {
        let points = try await marketKit.topPlatformMarketCapChart(platform: topPlatform.blockchain.uid, currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)

        let items = points.map { point -> MetricChartModule.Item in
            MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }

}
