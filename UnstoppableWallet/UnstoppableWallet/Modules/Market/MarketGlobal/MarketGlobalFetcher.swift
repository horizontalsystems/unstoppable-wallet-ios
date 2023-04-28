import Foundation
import MarketKit
import CurrencyKit
import Chart

class MarketGlobalFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let metricsType: MarketGlobalModule.MetricsType

    init(currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit, metricsType: MarketGlobalModule.MetricsType) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.metricsType = metricsType
    }

}

extension MarketGlobalFetcher: IMetricChartFetcher {

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

    func fetch(interval: HsTimePeriod) async throws -> MetricChartModule.ItemData {
        let points = try await marketKit.globalMarketPoints(currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)

        let items = points.map { point -> MetricChartModule.Item in
            let value: Decimal
            var indicators = [ChartIndicatorName: Decimal]()

            switch metricsType {
            case .defiCap: value = point.defiMarketCap
            case .totalMarketCap:
                value = point.marketCap
                indicators[.dominance] = point.btcDominance
            case .tvlInDefi: value = point.tvl
            case .volume24h: value = point.volume24h
            }

            return MetricChartModule.Item(value: value, indicators: indicators, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }

}
