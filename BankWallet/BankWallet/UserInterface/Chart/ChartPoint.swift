import Foundation

struct ChartPoint {
    let timestamp: TimeInterval
    let value: Decimal

    init(timestamp: TimeInterval, value: Decimal) {
        self.timestamp = timestamp
        self.value = value
    }
}

extension ChartPoint: Equatable {

    public static func ==(lhs: ChartPoint, rhs: ChartPoint) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.value == rhs.value
    }

}
