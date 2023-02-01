import RxSwift
import Foundation
import MarketKit
import Chart

class ProChartFetcher {
    private let marketKit: MarketKit.Kit
    private let coinUid: String
    private let type: CoinProChartModule.ProChartType

    init(marketKit: MarketKit.Kit, coinUid: String, type: CoinProChartModule.ProChartType) {
        self.marketKit = marketKit
        self.coinUid = coinUid
        self.type = type
    }

}

extension ProChartFetcher: IMetricChartConfiguration {
    var title: String { type.title }
    var description: String? { type.description }
    var poweredBy: String? { nil }

    var valueType: MetricChartModule.ValueType {
        switch type {
        case .activeAddresses, .txCount: return .counter
        default: return .compactCurrencyValue
        }
    }

}

extension ProChartFetcher: IMetricChartFetcher {

    func fetchSingle(currencyCode: String, interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        let single: Single<[ChartPoint]>
        switch type {
        case .volume: single = marketKit.dexVolumesSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval).map { $0.volumePoints }
        case .liquidity: single = marketKit.dexLiquiditySingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval).map { $0.volumePoints }
        case .txCount: single = marketKit.transactionDataSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval, platform: nil).map { response in
            zip(response.countPoints, response.volumePoints).map { ChartPoint(timestamp: $0.timestamp, value: $0.value, extra: [ChartPoint.volume: $1.value]) }
        }
        case .txVolume: single = marketKit.transactionDataSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval, platform: nil).map { $0.volumePoints }
        case .activeAddresses: single = marketKit.activeAddressesSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval, platform: nil).map { $0.countPoints }
        }

        return single.map { items in
            items.map {
                let volume: [ChartIndicatorName: Decimal]? = $0.extra[ChartPoint.volume].map { [.volume: $0] }
                return MetricChartModule.Item(value: $0.value, indicators: volume, timestamp: $0.timestamp)
            }
        }
    }

}
