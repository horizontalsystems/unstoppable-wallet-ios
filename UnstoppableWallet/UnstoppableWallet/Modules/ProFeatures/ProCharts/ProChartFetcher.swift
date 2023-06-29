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

    func fetch(interval: HsTimePeriod) async throws -> MetricChartModule.ItemData {
        switch type {
        case .cexVolume:
            let data = try await marketKit.cexVolumes(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
            return MetricChartModule.ItemData(
                    items: data.points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                    type: .aggregated(value: data.aggregatedValue)
            )
        case .dexVolume:
            let data = try await marketKit.dexVolumes(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
            return MetricChartModule.ItemData(
                    items: data.points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                    type: .aggregated(value: data.aggregatedValue)
            )
        case .dexLiquidity:
            let points = try await marketKit.dexLiquidity(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
            return MetricChartModule.ItemData(
                    items: points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                    type: .regular
            )
        case .activeAddresses:
            let points = try await marketKit.activeAddresses(coinUid: coin.uid, timePeriod: interval)
            return MetricChartModule.ItemData(
                    items: points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                    type: .regular
            )
        case .txCount:
            let data = try await marketKit.transactions(coinUid: coin.uid, timePeriod: interval)
            let volumes = data.points.map { $0.volume ?? 0 }
            return MetricChartModule.ItemData(
                    items: data.points.map {
                        MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp)
                    },
                    indicators: [ChartData.volume: volumes],
                    type: .aggregated(value: data.aggregatedValue)
            )
        case .tvl:
            let points = try await marketKit.marketInfoTvl(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
            return MetricChartModule.ItemData(
                    items: points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                    type: .regular
            )
        }
    }

}
