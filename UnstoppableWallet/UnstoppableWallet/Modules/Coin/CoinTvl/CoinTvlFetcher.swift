import RxSwift
import Foundation
import MarketKit
import Chart

class CoinTvlFetcher {
    private let marketKit: MarketKit.Kit
    private let coinUid: String

    init(marketKit: MarketKit.Kit, coinUid: String) {
        self.marketKit = marketKit
        self.coinUid = coinUid
    }

}

extension CoinTvlFetcher: IMetricChartConfiguration {
    var title: String { "coin_page.tvl".localized }
    var description: String? { "coin_page.tvl.description".localized  }
    var poweredBy: String { "DefiLlama API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue
    }

}

extension CoinTvlFetcher: IMetricChartFetcher {

    func fetchSingle(currencyCode: String, interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        marketKit
                .marketInfoTvlSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval)
                .map { points in
                    points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) }
                }
    }

}
