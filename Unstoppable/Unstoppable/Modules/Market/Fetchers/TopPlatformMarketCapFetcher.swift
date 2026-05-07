import Combine
import Foundation
import MarketKit

class TopPlatformMarketCapFetcher {
    private static let defaultPeriodTypes = [HsTimePeriod.week1, .month1, .month3].periodTypes
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let topPlatform: TopPlatform

    private(set) var startTime: TimeInterval?
    private let needUpdateIntervalsSubject = PassthroughSubject<Void, Never>()

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, topPlatform: TopPlatform) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.topPlatform = topPlatform
    }

    private func fetchStartTimeInterval() async throws {
        if startTime != nil {
            return
        }

        let timeInterval = try await marketKit.topPlatformMarketCapStart(platform: topPlatform.blockchain.uid)
        startTime = timeInterval

        needUpdateIntervalsSubject.send()
    }
}

extension TopPlatformMarketCapFetcher: IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyManager.baseCurrency)
    }

    var intervals: [HsPeriodType] {
        if let startTime {
            let periods = HsChartHelper.validIntervals(startTime: startTime)
            return periods.periodTypes + [.byStartTime(startTime)]
        }

        return Self.defaultPeriodTypes
    }

    var needUpdateIntervals: AnyPublisher<Void, Never> {
        needUpdateIntervalsSubject.eraseToAnyPublisher()
    }

    func fetch(interval: HsPeriodType) async throws -> MetricChartModule.ItemData {
        try await fetchStartTimeInterval()

        let points = try await marketKit.topPlatformMarketCapChart(
            platform: topPlatform.blockchain.uid,
            currencyCode: currencyManager.baseCurrency.code,
            periodType: interval
        )

        let items = points.map { point -> MetricChartModule.Item in
            MetricChartModule.Item(value: point.marketCap, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }
}
