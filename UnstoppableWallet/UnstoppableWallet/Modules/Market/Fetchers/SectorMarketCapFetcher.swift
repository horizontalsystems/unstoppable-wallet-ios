import Combine
import Foundation
import MarketKit

class SectorMarketCapFetcher {
    private static let defaultPeriodTypes = [HsTimePeriod.day1, .week1, .month1]
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let sector: CoinCategory

    private let needUpdateIntervalsSubject = PassthroughSubject<Void, Never>()

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, sector: CoinCategory) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.sector = sector
    }
}

extension SectorMarketCapFetcher: IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyManager.baseCurrency)
    }

    var intervals: [HsPeriodType] {
        Self.defaultPeriodTypes.periodTypes
    }

    var needUpdateIntervals: AnyPublisher<Void, Never> {
        needUpdateIntervalsSubject.eraseToAnyPublisher()
    }

    func fetch(interval: HsPeriodType) async throws -> MetricChartModule.ItemData {
        let points = try await marketKit.coinCategoryMarketCapChart(
            category: sector.uid,
            currencyCode: currencyManager.baseCurrency.code,
            timePeriod: HsTimePeriod(interval) ?? .day1
        )

        let items = points.map { point -> MetricChartModule.Item in
            MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }
}
