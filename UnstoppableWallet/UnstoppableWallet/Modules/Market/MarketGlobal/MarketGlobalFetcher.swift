import Foundation
import MarketKit
import Chart

class MarketGlobalFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let metricsType: MarketGlobalModule.MetricsType

    init(currencyManager: CurrencyManager, marketKit: MarketKit.Kit, metricsType: MarketGlobalModule.MetricsType) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.metricsType = metricsType
    }

}

extension MarketGlobalFetcher: IMetricChartFetcher {

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyManager.baseCurrency)
    }

    func fetch(interval: HsTimePeriod) async throws -> MetricChartModule.ItemData {
        let points = try await marketKit.globalMarketPoints(currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)

        var dominancePoints = [Decimal]()
        let items = points.map { point -> MetricChartModule.Item in
            let value: Decimal


            switch metricsType {
            case .defiCap: value = point.defiMarketCap
            case .totalMarketCap:
                value = point.marketCap
                dominancePoints.append(point.btcDominance)
            case .tvlInDefi: value = point.tvl
            case .volume24h: value = point.volume24h
            }

            return MetricChartModule.Item(value: value, timestamp: point.timestamp)
        }
        let indicators = [MarketGlobalModule.dominance: dominancePoints]
        return MetricChartModule.ItemData(items: items, indicators: indicators, type: .regular)
    }

}
