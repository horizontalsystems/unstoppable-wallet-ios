//import MarketKit
//import RxSwift
//import Foundation
//
//class CoinTvlFetcher {
//    private let rateManager: IRateManager
//    private let coinType: CoinType
//
//    init(rateManager: IRateManager, coinType: CoinType) {
//        self.rateManager = rateManager
//        self.coinType = coinType
//    }
//
//}
//
//extension CoinTvlFetcher: IMetricChartConfiguration {
//    var title: String { "coin_page.tvl".localized }
//    var description: String? { "coin_page.tvl.description".localized }
//    var poweredBy: String { "DefiLlama API" }
//
//    var valueType: MetricChartModule.ValueType {
//        .compactCurrencyValue
//    }
//
//}
//
//extension CoinTvlFetcher: IMetricChartFetcher {
//
//    func fetchSingle(currencyCode: String, timePeriod: TimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
//        Single.just([])
////        rateManager
////                .defiTvlPoints(coinType: coinType, currencyCode: currencyCode, fetchDiffPeriod: timePeriod)
////                .map { points in
////                    points.map { MetricChartModule.Item(value: $0.tvl, timestamp: TimeInterval($0.timestamp)) }
////                }
//    }
//
//}
