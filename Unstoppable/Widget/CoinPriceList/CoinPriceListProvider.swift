import Foundation
import SwiftUI
import WidgetKit

struct CoinPriceListProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> CoinPriceListEntry {
        let count: Int

        switch context.family {
        case .systemSmall, .systemMedium: count = 3
        default: count = 6
        }

        return CoinPriceListEntry(
            date: Date(),
            sortType: .highestCap,
            maxItemCount: count,
            items: (1 ... count).map { CoinItem.stub(index: $0) }
        )
    }

    func getSnapshot(for _: CoinPriceListIntent, in context: Context, completion: @escaping (CoinPriceListEntry) -> Void) {
        Task {
            let entry = try await fetch(sortType: .highestCap, family: context.family)
            completion(entry)
        }
    }

    func getTimeline(for configuration: CoinPriceListIntent, in context: Context, completion: @escaping (Timeline<CoinPriceListEntry>) -> Void) {
        Task {
            let entry = try await fetch(sortType: configuration.sortBy, family: context.family)

            if let nextUpdate = Calendar.current.date(byAdding: DateComponents(minute: 15), to: Date()) {
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }

    private func fetch(sortType: SortType, family: WidgetFamily) async throws -> CoinPriceListEntry {
        let storage = SharedLocalStorage()
        let currency = CurrencyManager(storage: storage).baseCurrency
        let apiProvider = ApiProvider()

        let listType: ApiProvider.ListType
        let listOrder: ApiProvider.ListOrder
        let limit: Int

        switch sortType {
        case .highestCap, .lowestCap, .unknown: listType = .mcap
        case .gainers, .losers: listType = .priceChange24h
        }

        switch sortType {
        case .highestCap, .gainers, .unknown: listOrder = .desc
        case .lowestCap, .losers: listOrder = .asc
        }

        switch family {
        case .systemSmall, .systemMedium: limit = 3
        default: limit = 6
        }

        let coins = try await apiProvider.listCoins(type: listType, order: listOrder, limit: limit, currencyCode: currency.code)

        return CoinPriceListEntry(
            date: Date(),
            sortType: sortType,
            maxItemCount: limit,
            items: coins.map { coin in
                CoinItem(
                    uid: coin.uid,
                    icon: coin.image,
                    code: coin.code,
                    marketCap: coin.marketCap.flatMap { ValueFormatter.formatShort(currency: currency, value: $0) },
                    rank: coin.rank.map { "\($0)" },
                    price: coin.formattedPrice(currency: currency),
                    priceChange: coin.formattedPriceChange(),
                    priceChangeType: coin.priceChangeType()
                )
            }
        )
    }
}
