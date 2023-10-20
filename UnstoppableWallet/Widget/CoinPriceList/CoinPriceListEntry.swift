import Foundation
import SwiftUI
import WidgetKit

struct CoinPriceListEntry: TimelineEntry {
    let date: Date
    let mode: CoinPriceListMode
    let sortType: SortType
    let maxItemCount: Int
    let items: [Item]

    struct Item {
        let uid: String
        let icon: Image?
        let code: String
        let name: String
        let price: String
        let priceChange: String
        let priceChangeType: PriceChangeType
    }
}
