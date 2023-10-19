import SwiftUI
import WidgetKit

@main
struct AppWidgetBundle: WidgetBundle {
    var body: some Widget {
        SingleCoinPriceWidget()
        TopCoinsWidget()
        WatchlistWidget()
    }
}
