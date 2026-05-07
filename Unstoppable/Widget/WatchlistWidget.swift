import Foundation
import SwiftUI
import WidgetKit

struct WatchlistWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: AppWidgetConstants.watchlistWidgetKind,
            provider: WatchlistProvider()
        ) { entry in
            if #available(iOS 17.0, *) {
                view(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                view(entry: entry)
                    .background()
            }
        }
        .contentMarginsDisabled()
        .configurationDisplayName("watchlist.title")
        .description("watchlist.description")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }

    @ViewBuilder private func view(entry: WatchlistEntry) -> some View {
        CoinListView(items: entry.items, maxItemCount: entry.maxItemCount, title: "watchlist.title", subtitle: title(sortBy: entry.sortBy))
    }

    private func title(sortBy: WatchlistSortBy) -> LocalizedStringKey {
        switch sortBy {
        case .manual: return "sort_type.manual"
        case .highestCap: return "sort_type.highest_cap"
        case .lowestCap: return "sort_type.lowest_cap"
        case .gainers: return "sort_type.gainers"
        case .losers: return "sort_type.losers"
        }
    }
}
