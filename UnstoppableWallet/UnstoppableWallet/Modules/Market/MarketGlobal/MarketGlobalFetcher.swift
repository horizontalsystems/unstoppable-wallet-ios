import XRatesKit
import RxSwift
import Foundation
import Chart

class MarketGlobalFetcher {
    private let rateManager: IRateManager
    private let metricsType: MarketGlobalModule.MetricsType

    init(rateManager: IRateManager, metricsType: MarketGlobalModule.MetricsType) {
        self.rateManager = rateManager
        self.metricsType = metricsType
    }

}

extension MarketGlobalFetcher: IMetricChartConfiguration {
    var title: String { metricsType.title }
    var description: String? { metricsType.description }
    var poweredBy: String { "DefiLlama API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue
    }

}

extension MarketGlobalFetcher {

    func fetchSingle(currencyCode: String, timePeriod: String) -> RxSwift.Single<[MetricChartModule.Item]> {
        let timePeriod = TimePeriod(rawValue: timePeriod)

        return rateManager
                .globalMarketInfoPointsSingle(currencyCode: currencyCode, timePeriod: timePeriod)
                .map { [weak self] points in
                    let result = points.map { point -> MetricChartModule.Item in
                        let value: Decimal
                        var additional = [ChartIndicatorName: Decimal]()

                        switch self?.metricsType {
                        case .defiCap: value = point.marketCapDefi
                        case .totalMarketCap:
                            value = point.marketCap
                            additional[.dominance] = point.dominanceBtc
                        case .tvlInDefi: value = point.tvl
                        case .none, .volume24h: value = point.volume24h
                        }

                        return MetricChartModule.Item(value: value, indicators: additional, timestamp: point.timestamp)
                    }


                    return result
                }
    }

}
