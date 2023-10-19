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
            title: "Top Coins",
            sortType: "Highest Cap",
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
        let currency = CurrencyManager(storage: SharedLocalStorage()).baseCurrency
        let apiProvider = ApiProvider(baseUrl: "https://api-dev.blocksdecoded.com")

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

        let coins = try await apiProvider.listCoins(type: listType, order: listOrder, limit: limit, currencyCode: currency.code)

        return CoinPriceListEntry(
            date: Date(),
            title: "Top Coins",
            sortType: title(sortType: sortType),
            items: coins.map { coin in
                let iconUrl = "https://cdn.blocksdecoded.com/coin-icons/32px/\(coin.uid)@3x.png"
                let coinIcon = URL(string: iconUrl).flatMap { try? Data(contentsOf: $0) }.flatMap { UIImage(data: $0) }.map { Image(uiImage: $0) }

                return CoinPriceListEntry.Item(
                    uid: coin.uid,
                    icon: coinIcon,
                    code: coin.code,
                    name: coin.name,
                    price: coin.price.flatMap { ValueFormatter.format(currency: currency, value: $0) } ?? "n/a",
                    priceChange: coin.priceChange24h.flatMap { ValueFormatter.format(percentValue: $0) } ?? "n/a",
                    priceChangeType: coin.priceChange24h.map { $0 >= 0 ? .up : .down } ?? .unknown
                )
            }
        )
    }

    private func title(sortType: SortType) -> String {
        switch sortType {
        case .highestCap, .unknown: return "Highest Cap"
        case .lowestCap: return "Lowest Cap"
        case .highestVolume: return "Highest Volume"
        case .lowestVolume: return "Lowest Volume"
        case .topGainers: return "Top Gainers"
        case .topLosers: return "Top Losers"
        }
    }
}
