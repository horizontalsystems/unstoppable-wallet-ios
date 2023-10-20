import Foundation
import SwiftUI
import WidgetKit

struct WatchlistWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: AppWidgetConstants.watchlistWidgetKind,
            intent: CoinPriceListIntent.self,
            provider: CoinPriceListProvider(mode: .watchlist)
        ) { entry in
            if #available(iOS 17.0, *) {
                CoinPriceListView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CoinPriceListView(entry: entry)
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
}
