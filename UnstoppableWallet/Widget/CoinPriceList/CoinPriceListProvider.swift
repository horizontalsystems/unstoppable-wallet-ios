import Foundation
import SwiftUI
import WidgetKit

struct CoinPriceListProvider: IntentTimelineProvider {
    let mode: CoinPriceListMode

    func placeholder(in context: Context) -> CoinPriceListEntry {
        let count: Int

        switch context.family {
        case .systemSmall, .systemMedium: count = 3
        default: count = 6
        }

        return CoinPriceListEntry(
            date: Date(),
            mode: mode,
            sortType: .highestCap,
            maxItemCount: count,
            items: (1 ... count).map { index in
                CoinPriceListEntry.Item(
                    uid: "coin\(index)",
                    icon: nil,
                    code: "COD\(index)",
                    name: "Coin Name \(index)",
                    price: "$1234",
                    priceChange: "1.23",
                    priceChangeType: .unknown
                )
            }
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
        case .highestVolume, .lowestVolume: listType = .volume
        case .topGainers, .topLosers: listType = .price
        }

        switch sortType {
        case .highestCap, .highestVolume, .topGainers, .unknown: listOrder = .desc
        case .lowestCap, .lowestVolume, .topLosers: listOrder = .asc
        }

        switch family {
        case .systemSmall, .systemMedium: limit = 3
        default: limit = 6
        }

        let coins: [Coin]

        switch mode {
        case .topCoins:
            coins = try await apiProvider.listCoins(type: listType, order: listOrder, limit: limit, currencyCode: currency.code)
        case .watchlist:
            let coinUids: [String]? = storage.value(for: AppWidgetConstants.keyFavoriteCoinUids)

            if let coinUids, !coinUids.isEmpty {
                coins = try await apiProvider.listCoins(uids: coinUids, type: listType, order: listOrder, limit: limit, currencyCode: currency.code)
            } else {
                coins = []
            }
        }

        return CoinPriceListEntry(
            date: Date(),
            mode: mode,
            sortType: sortType,
            maxItemCount: limit,
            items: coins.map { coin in
                CoinPriceListEntry.Item(
                    uid: coin.uid,
                    icon: coin.image,
                    code: coin.code,
                    name: coin.name,
                    price: coin.formattedPrice(currency: currency),
                    priceChange: coin.formattedPriceChange,
                    priceChangeType: coin.priceChangeType
                )
            }
        )
    }
}
