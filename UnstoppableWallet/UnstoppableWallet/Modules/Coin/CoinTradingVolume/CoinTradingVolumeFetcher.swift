import MarketKit
import RxSwift
import Foundation

class CoinTradingVolumeFetcher {
    private let coinType: CoinType
    private let coinTitle: String

    init(coinType: CoinType, coinTitle: String) {
        self.coinType = coinType
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

    func fetchSingle(currencyCode: String, timePeriod: MarketKit.TimePeriod) -> Single<[MetricChartModule.Item]> {
        Single.just([])
    }

//    func fetchSingle(currencyCode: String, timePeriod: TimePeriod) -> Single<[MetricChartModule.Item]> {
//        rateManager
//                .coinMarketPointsSingle(coinType: coinType, currencyCode: currencyCode, fetchDiffPeriod: timePeriod)
//                .map { points in
//                    points.map {
//                        MetricChartModule.Item(value: $0.volume24h, timestamp: TimeInterval($0.timestamp))
//                    }
//                }
//    }

}
