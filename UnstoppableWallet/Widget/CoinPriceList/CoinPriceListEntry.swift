import Foundation
import SwiftUI
import WidgetKit

struct CoinPriceListEntry: TimelineEntry {
    let date: Date
    let title: String
    let sortType: String
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
