import MarketKit
import CurrencyKit
import RxSwift
import Foundation

class CoinTradingVolumeFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let coinUid: String
    private let coinTitle: String

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, coinUid: String, coinTitle: String) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.coinUid = coinUid
        self.coinTitle = coinTitle
    }

}

extension CoinTradingVolumeFetcher: IMetricChartConfiguration {
    var title: String { "coin_page.trading_volume".localized }
    var description: String? { "coin_page.trading_volume.description".localized(coinTitle) }
    var poweredBy: String? { "CoinGecko API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

}

extension CoinTradingVolumeFetcher: IMetricChartFetcher {

    var intervals: [HsTimePeriod] {
        [.month1, .month3, .month6, .year1]
    }

    func fetchSingle(interval: HsTimePeriod) -> Single<[MetricChartModule.Item]> {
        marketKit
            .chartInfoSingle(coinUid: coinUid, currencyCode: currencyKit.baseCurrency.code, periodType: .byPeriod(interval))
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
