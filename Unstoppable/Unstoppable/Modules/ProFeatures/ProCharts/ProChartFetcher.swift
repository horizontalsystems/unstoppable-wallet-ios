import Chart
import Foundation
import MarketKit

class ProChartFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let coin: Coin
    private let type: CoinProChartModule.ProChartType

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, coin: Coin, type: CoinProChartModule.ProChartType) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.coin = coin
        self.type = type
    }
}

extension ProChartFetcher: IMetricChartFetcher {
    var intervals: [HsPeriodType] {
        switch type {
        case .cexVolume, .dexVolume, .dexLiquidity, .activeAddresses, .txCount:
            return [HsTimePeriod.week1, .week2, .month1, .month3, .month6, .year1].periodTypes
        case .tvl:
            return [HsTimePeriod.day1, .week1, .week2, .month1, .month3, .month6, .year1].periodTypes
        }
    }

    var valueType: MetricChartModule.ValueType {
        switch type {
        case .activeAddresses, .txCount: return .counter
        default: return .compactCurrencyValue(currencyManager.baseCurrency)
        }
    }

    func fetch(interval: HsPeriodType) async throws -> MetricChartModule.ItemData {
        guard case let .byPeriod(interval) = interval else {
            throw MetricChartModule.FetchError.onlyHsTimePeriod
        }

        switch type {
        case .cexVolume:
            let data = try await marketKit.cexVolumes(coinUid: coin.uid, currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)
            return MetricChartModule.ItemData(
                items: data.points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                type: .aggregated(value: data.aggregatedValue)
            )
        case .dexVolume:
            let data = try await marketKit.dexVolumes(coinUid: coin.uid, currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)
            return MetricChartModule.ItemData(
                items: data.points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                type: .aggregated(value: data.aggregatedValue)
            )
        case .dexLiquidity:
            let points = try await marketKit.dexLiquidity(coinUid: coin.uid, currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)
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
            let points = try await marketKit.marketInfoTvl(coinUid: coin.uid, currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)
            return MetricChartModule.ItemData(
                items: points.map { MetricChartModule.Item(value: $0.value, timestamp: $0.timestamp) },
                type: .regular
            )
        }
    }
}
