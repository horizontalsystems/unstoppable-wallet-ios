import Foundation
import SwiftUI
import WidgetKit

struct WatchlistEntry: TimelineEntry {
    let date: Date
    let sortBy: WatchlistSortBy
    let maxItemCount: Int
    let items: [CoinItem]
}
