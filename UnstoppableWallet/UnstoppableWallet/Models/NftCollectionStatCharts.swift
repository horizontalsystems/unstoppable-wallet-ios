import Foundation
import Chart
import MarketKit

struct NftCollectionStatCharts {
    let oneDayVolumePoints: [PricePoint]
    let averagePricePoints: [PricePoint]
    let floorPricePoints: [PricePoint]
    let oneDaySalesPoints: [Point]
}

extension NftCollectionStatCharts {

    class PricePoint: Point {
        let coin: PlatformCoin?

        init(timestamp: TimeInterval, value: Decimal, coin: PlatformCoin?) {
            self.coin = coin
            super.init(timestamp: timestamp, value: value)
        }

    }

    class Point {
        let timestamp: TimeInterval
        let value: Decimal

        init(timestamp: TimeInterval, value: Decimal) {
            self.timestamp = timestamp
            self.value = value
        }

    }

}
