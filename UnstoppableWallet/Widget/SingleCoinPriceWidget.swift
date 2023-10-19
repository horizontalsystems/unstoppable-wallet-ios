import Foundation
import SwiftUI
import WidgetKit

struct SingleCoinPriceWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: AppWidgetConstants.singleCoinPriceWidgetKind,
            intent: SingleCoinPriceIntent.self,
            provider: SingleCoinPriceProvider()
        ) { entry in
            if #available(iOS 17.0, *) {
                SingleCoinPriceView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SingleCoinPriceView(entry: entry)
                    .background()
            }
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Coin Price")
        .description("Displays price for certain coin.")
        .supportedFamilies([
            .systemSmall,
        ])
    }
}
