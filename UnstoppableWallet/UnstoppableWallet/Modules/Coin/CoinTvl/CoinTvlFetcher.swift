import RxSwift
import Foundation
import MarketKit
import CurrencyKit
import Chart

class CoinTvlFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let coinUid: String

    init(currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit, coinUid: String) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.coinUid = coinUid
    }

}

extension CoinTvlFetcher: IMetricChartConfiguration {
    var title: String { "coin_page.tvl".localized }
    var description: String? { "coin_page.tvl.description".localized  }
    var poweredBy: String? { "DefiLlama API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

}

extension CoinTvlFetcher: IMetricChartFetcher {

    func fetchSingle(interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        marketKit
                .marketInfoTvlSingle(coinUid: coinUid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                .map { points in
                    points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) }
                }
    }

}
