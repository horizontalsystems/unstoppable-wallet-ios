import MarketKit
import RxSwift
import Foundation

class CoinTradingVolumeFetcher {
    private let marketKit: MarketKit.Kit
    private let coinUid: String
    private let coinTitle: String

    init(marketKit: MarketKit.Kit, coinUid: String, coinTitle: String) {
        self.marketKit = marketKit
        self.coinUid = coinUid
        self.coinTitle = coinTitle
    }

}

extension CoinTradingVolumeFetcher: IMetricChartConfiguration {
    var title: String { "coin_page.trading_volume".localized }
    var description: String? { "coin_page.trading_volume.description".localized(coinTitle) }
    var poweredBy: String { "CoinGecko API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue
    }

}

extension CoinTradingVolumeFetcher: IMetricChartFetcher {

    var intervals: [HsTimePeriod] {
        [.month1, .month3, .month6, .year1]
    }

    func fetchSingle(currencyCode: String, interval: HsTimePeriod) -> Single<[MetricChartModule.Item]> {
        marketKit
            .chartInfoSingle(coinUid: coinUid, currencyCode: currencyCode, interval: interval)
            .map { info in
                info
                    .points
                    .filter { $0.timestamp >= info.startTimestamp }
                    .compactMap { point in
                        point.extra[ChartPoint.volume].map { MetricChartModule.Item(value: $0, timestamp: point.timestamp) }
                }
            }
    }

}
