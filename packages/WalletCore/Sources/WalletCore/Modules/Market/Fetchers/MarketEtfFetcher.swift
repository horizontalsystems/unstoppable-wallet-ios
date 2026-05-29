import Chart
import Combine
import Foundation
import MarketKit

class MarketEtfFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let category: EtfCategory

    private let needUpdateSubject = PassthroughSubject<Void, Never>()

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, category: EtfCategory) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.category = category
    }
}

extension MarketEtfFetcher: IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyManager.baseCurrency)
    }

    var needUpdatePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    var intervals: [HsPeriodType] {
        var result = [HsTimePeriod.month1, .month3, .month6, .year1].periodTypes
        result.append(contentsOf: [HsPeriodType.byStartTime(0)])

        return result
    }

    func fetch(interval: HsPeriodType) async throws -> MetricChartModule.ItemData {
        var timePeriod: HsTimePeriod?
        switch interval {
        case let .byPeriod(period): timePeriod = period
        default: ()
        }

        let points = try await marketKit.etfPoints(category: category.rawValue, currencyCode: currencyManager.baseCurrency.code, timePeriod: timePeriod)

        var items = [MetricChartModule.Item]()
        var totalInflow = [Decimal]()
        var dailyInflow = [Decimal]()
        var totalAssets = [Decimal]()
        for point in points.sorted(by: { p1, p2 in p1.date < p2.date }) {
            items.append(MetricChartModule.Item(value: point.dailyInflow, timestamp: point.date.timeIntervalSince1970))
            totalInflow.append(point.totalInflow)
            dailyInflow.append(point.dailyInflow)
            totalAssets.append(point.totalAssets)
        }
        return MetricChartModule.ItemData(
            items: items,
            indicators: [
                MarketGlobalModule.totalInflow: totalInflow,
                MarketGlobalModule.dailyInflow: dailyInflow,
                MarketGlobalModule.totalAssets: totalAssets,
            ],
            type: .etf
        )
    }
}

extension MarketEtfFetcher {
    public enum EtfCategory: String, CaseIterable {
        case btc
        case eth
    }
}
