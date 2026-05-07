import Foundation
import SwiftUI
import WidgetKit

struct TopCoinsWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: AppWidgetConstants.topCoinsWidgetKind,
            intent: CoinPriceListIntent.self,
            provider: CoinPriceListProvider()
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
        .configurationDisplayName("top_coins.title")
        .description("top_coins.description")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }

    @ViewBuilder private func view(entry: CoinPriceListEntry) -> some View {
        CoinListView(items: entry.items, maxItemCount: entry.maxItemCount, title: "top_coins.title", subtitle: title(sortType: entry.sortType))
    }

    private func title(sortType: SortType) -> LocalizedStringKey {
        switch sortType {
        case .highestCap, .unknown: return "sort_type.highest_cap"
        case .lowestCap: return "sort_type.lowest_cap"
        case .gainers: return "sort_type.gainers"
        case .losers: return "sort_type.losers"
        }
    }
}
