import RxSwift
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

    func fetchSingle(interval: HsTimePeriod) -> RxSwift.Single<MetricChartModule.ItemData> {
        marketKit
                .globalMarketPointsSingle(currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                .map { [weak self] points in
                    let items = points.map { point -> MetricChartModule.Item in
                        let value: Decimal
                        var additional = [ChartIndicatorName: Decimal]()

                        switch self?.metricsType {
                        case .defiCap: value = point.defiMarketCap
                        case .totalMarketCap:
                            value = point.marketCap
                            additional[.dominance] = point.btcDominance
                        case .tvlInDefi: value = point.tvl
                        case .none, .volume24h: value = point.volume24h
                        }

                        return MetricChartModule.Item(value: value, indicators: additional, timestamp: point.timestamp)
                    }

                    return MetricChartModule.ItemData(items: items, type: .regular)
                }
    }

}
