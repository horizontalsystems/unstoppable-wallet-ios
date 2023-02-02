import RxSwift
import Foundation
import MarketKit
import CurrencyKit
import Chart

class ProChartFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let coin: Coin
    private let type: CoinProChartModule.ProChartType

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, coin: Coin, type: CoinProChartModule.ProChartType) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.coin = coin
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
        case .txVolume: return .compactCoinValue(coin)
        default: return .compactCurrencyValue(currencyKit.baseCurrency)
        }
    }

}

extension ProChartFetcher: IMetricChartFetcher {

    func fetchSingle(interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        let single: Single<[ChartPoint]>
        switch type {
        case .volume: single = marketKit.dexVolumesSingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval).map { $0.volumePoints }
        case .liquidity: single = marketKit.dexLiquiditySingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval).map { $0.volumePoints }
        case .txCount: single = marketKit.transactionDataSingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval, platform: nil).map { response in
            zip(response.countPoints, response.volumePoints).map { ChartPoint(timestamp: $0.timestamp, value: $0.value, extra: [ChartPoint.volume: $1.value]) }
        }
        case .txVolume: single = marketKit.transactionDataSingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval, platform: nil).map { $0.volumePoints }
        case .activeAddresses: single = marketKit.activeAddressesSingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval, platform: nil).map { $0.countPoints }
        }

        return single.map { items in
            items.map {
                let volume: [ChartIndicatorName: Decimal]? = $0.extra[ChartPoint.volume].map { [.volume: $0] }
                return MetricChartModule.Item(value: $0.value, indicators: volume, timestamp: $0.timestamp)
            }
        }
    }

}
