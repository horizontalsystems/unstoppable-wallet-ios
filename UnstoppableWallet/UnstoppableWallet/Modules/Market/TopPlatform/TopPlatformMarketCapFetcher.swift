import RxSwift
import MarketKit
import CurrencyKit

class TopPlatformMarketCapFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let topPlatform: TopPlatform

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, topPlatform: TopPlatform) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.topPlatform = topPlatform
    }

}

extension TopPlatformMarketCapFetcher: IMetricChartFetcher {

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

    var intervals: [HsTimePeriod] {
        [.day1, .week1, .month1]
    }

    func fetchSingle(interval: HsTimePeriod) -> RxSwift.Single<MetricChartModule.ItemData> {
        marketKit
                .topPlatformMarketCapChartSingle(platform: topPlatform.blockchain.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                .map { points in
                    let items = points.map { point -> MetricChartModule.Item in
                        MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
                    }

                    return MetricChartModule.ItemData(items: items, type: .regular)
                }
    }

}
