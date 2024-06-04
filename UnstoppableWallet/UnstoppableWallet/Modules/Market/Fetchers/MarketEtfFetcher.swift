import Chart
import Combine
import Foundation
import MarketKit

class MarketEtfFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager

    private let needUpdateSubject = PassthroughSubject<Void, Never>()

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
    }
}

extension MarketEtfFetcher: IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyManager.baseCurrency)
    }

    var needUpdatePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    var intervals: [HsPeriodType] { [] }

    func fetch(interval _: HsPeriodType) async throws -> MetricChartModule.ItemData {
        let points = try await marketKit.etfPoints(currencyCode: currencyManager.baseCurrency.code)

        var items = [MetricChartModule.Item]()
        var totalInflow = [Decimal]()
        var totalAssets = [Decimal]()
        for point in points.sorted(by: { p1, p2 in p1.date < p2.date }) {
            items.append(MetricChartModule.Item(value: point.dailyInflow, timestamp: point.date.timeIntervalSince1970))
            totalInflow.append(point.totalInflow)
            totalAssets.append(point.totalAssets)
        }
        return MetricChartModule.ItemData(
            items: items,
            indicators: [
                MarketGlobalModule.totalInflow: totalInflow,
                MarketGlobalModule.totalAssets: totalAssets,
            ],
            type: .etf
        )
    }
}
