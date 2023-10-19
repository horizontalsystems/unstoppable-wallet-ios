import Foundation
import SwiftUI
import WidgetKit

struct SingleCoinPriceEntry: TimelineEntry {
    let date: Date
    let coinUid: String
    let coinIcon: Image?
    let coinCode: String
    let price: String
    let priceChange: String
    let priceChangeType: PriceChangeType
    let chartPoints: [ChartPoint]?

    struct ChartPoint: Identifiable {
        let date: Date
        let value: Decimal

        var id: Date {
            date
        }
    }
}
