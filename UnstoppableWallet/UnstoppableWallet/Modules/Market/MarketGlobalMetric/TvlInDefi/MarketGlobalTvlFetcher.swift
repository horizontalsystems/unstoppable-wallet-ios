import Foundation
import Combine
import MarketKit
import CurrencyKit
import Chart

class MarketGlobalTvlFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let service: MarketGlobalTvlMetricService

    private let needUpdateSubject = PassthroughSubject<Void, Never>()

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, marketGlobalTvlPlatformService: MarketGlobalTvlMetricService) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        service = marketGlobalTvlPlatformService
    }

}

extension MarketGlobalTvlFetcher: IMetricChartFetcher {

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

    var needUpdatePublisher: AnyPublisher<Void, Never> {
        service.$marketPlatformField.map { _ in () }.eraseToAnyPublisher()
    }

    func fetch(interval: HsTimePeriod) async throws -> MetricChartModule.ItemData {
        let points = try await marketKit.marketInfoGlobalTvl(platform: service.marketPlatformField.chain, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)

        let items = points.map { point -> MetricChartModule.Item in
            MetricChartModule.Item(value: point.value, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }

}
