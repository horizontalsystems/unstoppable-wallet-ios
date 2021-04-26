import XRatesKit
import RxSwift
import Foundation

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

    var valueType: MetricChartModule.ValueType {
        switch metricsType {
        case .btcDominance: return .percent
        default: return .compactCurrencyValue
        }
    }

}

extension MarketGlobalFetcher: IMetricChartFetcher {

    func fetchSingle(currencyCode: String, timePeriod: TimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        rateManager
                .globalMarketInfoPointsSingle(currencyCode: currencyCode, timePeriod: timePeriod)
                .map { [weak self] points in
                    points.map { point in
                        let value: Decimal

                        switch self?.metricsType {
                        case .defiCap: value = point.marketCapDefi
                        case .btcDominance: value = point.dominanceBtc
                        case .tvlInDefi: value = point.tvl
                        case .none, .volume24h: value = point.volume24h
                        }

                        return MetricChartModule.Item(value: value, timestamp: point.timestamp)
                    }
                }
    }

}
