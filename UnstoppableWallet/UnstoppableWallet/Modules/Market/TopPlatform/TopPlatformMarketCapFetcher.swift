import RxSwift
import MarketKit

class TopPlatformMarketCapFetcher {
    private let marketKit: MarketKit.Kit
    private let topPlatform: TopPlatform

    init(marketKit: MarketKit.Kit, topPlatform: TopPlatform) {
        self.marketKit = marketKit
        self.topPlatform = topPlatform
    }

}

extension TopPlatformMarketCapFetcher: IMetricChartConfiguration {

    var title: String {
        topPlatform.blockchain.name
    }

    var description: String? {
        "some description"
    }

    var poweredBy: String {
        "HorizontalSystems API"
    }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue
    }

}

extension TopPlatformMarketCapFetcher: IMetricChartFetcher {

    var intervals: [HsTimePeriod] {
        [.day1, .week1, .month1]
    }

    func fetchSingle(currencyCode: String, interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        marketKit
                .topPlatformMarketCapChartSingle(platform: topPlatform.blockchain.uid, currencyCode: currencyCode, timePeriod: interval)
                .map { points in
                    points.map { point -> MetricChartModule.Item in
                        MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
                    }
                }
    }

}
