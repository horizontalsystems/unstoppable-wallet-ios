import Foundation
import SwiftUI
import WidgetKit

struct WatchlistProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchlistEntry {
        let count: Int

        switch context.family {
        case .systemSmall, .systemMedium: count = 3
        default: count = 6
        }

        return WatchlistEntry(
            date: Date(),
            sortBy: .gainers,
            maxItemCount: count,
            items: (1 ... count).map { CoinItem.stub(index: $0) }
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchlistEntry) -> Void) {
        Task {
            let entry = try await fetch(family: context.family)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchlistEntry>) -> Void) {
        Task {
            let entry = try await fetch(family: context.family)

            if let nextUpdate = Calendar.current.date(byAdding: DateComponents(minute: 15), to: Date()) {
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }

    private func fetch(family: WidgetFamily) async throws -> WatchlistEntry {
        let storage = SharedLocalStorage()
        let watchlistManager = WatchlistManager(storage: storage)
        let currency = CurrencyManager(storage: storage).baseCurrency
        let apiProvider = ApiProvider()

        let listType: ApiProvider.ListType
        let listOrder: ApiProvider.ListOrder
        let limit: Int

        switch watchlistManager.sortBy {
        case .highestCap, .lowestCap: listType = .mcap
        case .gainers, .losers, .manual:
            switch watchlistManager.timePeriod {
            case .day1: listType = .priceChange24h
            case .week1: listType = .priceChange1w
            case .month1: listType = .priceChange1m
            case .month3: listType = .priceChange3m
            }
        }

        switch watchlistManager.sortBy {
        case .highestCap, .gainers, .manual: listOrder = .desc
        case .lowestCap, .losers: listOrder = .asc
        }

        switch family {
        case .systemSmall, .systemMedium: limit = 3
        default: limit = 6
        }

        let coinUids: [String]

        switch watchlistManager.sortBy {
        case .manual:
            coinUids = Array(watchlistManager.coinUids.prefix(limit))
        default:
            coinUids = watchlistManager.coinUids
        }

        let coins: [Coin]

        if !coinUids.isEmpty {
            let apiCoins = try await apiProvider.listCoins(uids: coinUids, type: listType, order: listOrder, limit: limit, currencyCode: currency.code)

            switch watchlistManager.sortBy {
            case .manual:
                coins = coinUids.compactMap { uid in apiCoins.first { $0.uid == uid } }
            default:
                coins = apiCoins
            }
        } else {
            coins = []
        }

        return WatchlistEntry(
            date: Date(),
            sortBy: watchlistManager.sortBy,
            maxItemCount: limit,
            items: coins.map { coin in
                CoinItem(
                    uid: coin.uid,
                    icon: coin.image,
                    code: coin.code,
                    marketCap: coin.marketCap.flatMap { ValueFormatter.formatShort(currency: currency, value: $0) },
                    rank: coin.rank.map { "\($0)" },
                    price: coin.formattedPrice(currency: currency),
                    priceChange: coin.formattedPriceChange(timePeriod: watchlistManager.timePeriod),
                    priceChangeType: coin.priceChangeType(timePeriod: watchlistManager.timePeriod)
                )
            }
        )
    }
}
