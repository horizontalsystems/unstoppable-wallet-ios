import Chart
import Combine
import Foundation
import MarketKit

class MarketGlobalTvlFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let service: MarketGlobalTvlMetricService

    private let needUpdateSubject = PassthroughSubject<Void, Never>()

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, marketGlobalTvlPlatformService: MarketGlobalTvlMetricService) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        service = marketGlobalTvlPlatformService
    }
}

extension MarketGlobalTvlFetcher: IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyManager.baseCurrency)
    }

    var needUpdatePublisher: AnyPublisher<Void, Never> {
        service.$marketPlatformField.map { _ in () }.eraseToAnyPublisher()
    }

    func fetch(interval: HsPeriodType) async throws -> MetricChartModule.ItemData {
        guard case let .byPeriod(interval) = interval else {
            throw MetricChartModule.FetchError.onlyHsTimePeriod
        }

        let points = try await marketKit.marketInfoGlobalTvl(platform: service.marketPlatformField.chain, currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)

        let items = points.map { point -> MetricChartModule.Item in
            MetricChartModule.Item(value: point.value, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }
}
