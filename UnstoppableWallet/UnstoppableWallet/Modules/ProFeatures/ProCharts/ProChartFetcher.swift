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

extension ProChartFetcher: IMetricChartFetcher {

    var intervals: [HsTimePeriod] {
        switch type {
        case .cexVolume, .dexVolume, .dexLiquidity, .activeAddresses, .txCount:
            return [.week1, .week2, .month1, .month3, .month6, .year1]
        case .tvl:
            return [.day1, .week1, .week2, .month1, .month3, .month6, .year1]
        }
    }

    var valueType: MetricChartModule.ValueType {
        switch type {
        case .activeAddresses, .txCount: return .counter
        default: return .compactCurrencyValue(currencyKit.baseCurrency)
        }
    }

    func fetchSingle(interval: HsTimePeriod) -> RxSwift.Single<MetricChartModule.ItemData> {
        switch type {
        case .cexVolume:
            return marketKit.cexVolumesSingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                    .map { data in
                        MetricChartModule.ItemData(
                                items: data.points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                                type: .aggregated(value: data.aggregatedValue)
                        )
                    }
        case .dexVolume:
            return marketKit.dexVolumesSingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                    .map { data in
                        MetricChartModule.ItemData(
                                items: data.points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                                type: .aggregated(value: data.aggregatedValue)
                        )
                    }
        case .dexLiquidity:
            return marketKit.dexLiquiditySingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                    .map { points in
                        MetricChartModule.ItemData(
                                items: points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                                type: .regular
                        )
                    }
        case .activeAddresses:
            return marketKit.activeAddressesSingle(coinUid: coin.uid, timePeriod: interval)
                    .map { points in
                        MetricChartModule.ItemData(
                                items: points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                                type: .regular
                        )
                    }
        case .txCount:
            return marketKit.transactionsSingle(coinUid: coin.uid, timePeriod: interval)
                    .map { data in
                        MetricChartModule.ItemData(
                                items: data.points.map {
                                    let indicators: [ChartIndicatorName: Decimal]? = $0.volume.map { [.volume: $0] }
                                    return MetricChartModule.Item(value: $0.value, indicators: indicators, timestamp: $0.timestamp)
                                },
                                type: .aggregated(value: data.aggregatedValue)
                        )
                    }
        case .tvl:
            return marketKit.marketInfoTvlSingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                    .map { points in
                        MetricChartModule.ItemData(
                                items: points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                                type: .regular
                        )
                    }
        }
    }

}
