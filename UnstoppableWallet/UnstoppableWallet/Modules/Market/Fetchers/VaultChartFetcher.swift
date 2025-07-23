import Combine
import Foundation
import MarketKit

class VaultChartFetcher {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let vault: Vault

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, vault: Vault) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.vault = vault
    }
}

extension VaultChartFetcher: IMetricChartFetcher {
    var valueType: MetricChartModule.ValueType {
        .percent
    }

    var intervals: [HsPeriodType] {
        [HsTimePeriod.day1, .week1, .week2, .month1, .month3].periodTypes
    }

    func fetch(interval: HsPeriodType) async throws -> MetricChartModule.ItemData {
        guard case let .byPeriod(interval) = interval else {
            throw MetricChartModule.FetchError.onlyHsTimePeriod
        }

        let vault = try await marketKit.vault(address: vault.address, currencyCode: currencyManager.baseCurrency.code, timePeriod: interval)

        let points = vault.apyChart ?? []

        let items = points.map { point -> MetricChartModule.Item in
            MetricChartModule.Item(value: point.apy, timestamp: point.timestamp)
        }

        return MetricChartModule.ItemData(items: items, type: .regular)
    }
}
