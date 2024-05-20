import Foundation
import SwiftUI
import WidgetKit

struct CoinPriceListEntry: TimelineEntry {
    let date: Date
    let sortType: SortType
    let maxItemCount: Int
    let items: [CoinItem]
}

struct CoinItem {
    let uid: String
    let icon: Image?
    let code: String
    let marketCap: String?
    let rank: String?
    let price: String
    let priceChange: String
    let priceChangeType: PriceChangeType

    static func stub(index: Int) -> CoinItem {
        CoinItem(
            uid: "coin\(index)",
            icon: nil,
            code: "COD\(index)",
            marketCap: "$1.23M",
            rank: "\(index)",
            price: "$1234",
            priceChange: "1.23",
            priceChangeType: .unknown
        )
    }
}
