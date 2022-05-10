import RxSwift
import Foundation
import MarketKit
import Chart

class ProChartFetcher {
    private let proFeaturesManager: ProFeaturesAuthorizationManager
    private let marketKit: MarketKit.Kit
    private let coinUid: String
    private let type: CoinProChartModule.ProChartType

    init(marketKit: MarketKit.Kit, proFeaturesManager: ProFeaturesAuthorizationManager, coinUid: String, type: CoinProChartModule.ProChartType) {
        self.marketKit = marketKit
        self.proFeaturesManager = proFeaturesManager
        self.coinUid = coinUid
        self.type = type
    }

}

extension ProChartFetcher: IMetricChartConfiguration {
    var title: String { type.title }
    var description: String? { nil }
    var poweredBy: String { "HorizontalSystems API" }

    var valueType: MetricChartModule.ValueType {
        switch type {
        case .activeAddresses, .txCount: return .counter
        default: return .compactCurrencyValue
        }
    }

}

extension ProChartFetcher: IMetricChartFetcher {

    func fetchSingle(currencyCode: String, interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        let key = proFeaturesManager.sessionKey(type: .mountainYak)

        let single: Single<[ChartPoint]>
        switch type {
        case .volume: single = marketKit.dexVolumesSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval, sessionKey: key).map { $0.volumePoints }
        case .liquidity: single = marketKit.dexLiquiditySingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval, sessionKey: key).map { $0.volumePoints }
        case .txCount: single = marketKit.transactionDataSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval, platform: nil, sessionKey: key).map { $0.countPoints }
        case .txVolume: single = marketKit.transactionDataSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval, platform: nil, sessionKey: key).map { $0.volumePoints }
        case .activeAddresses: single = marketKit.activeAddressesSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: interval, sessionKey: key).map { $0.countPoints }
        }

        return single.map { items in
            items.map {
                MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp)
            }
        }
    }

}
