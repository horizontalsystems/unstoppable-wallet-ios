import Foundation
import SwiftUI
import WidgetKit

struct TopCoinsWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: AppWidgetConstants.topCoinsWidgetKind,
            intent: CoinPriceListIntent.self,
            provider: CoinPriceListProvider(mode: .topCoins)
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
        .configurationDisplayName("top_coins.title")
        .description("top_coins.description")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}
