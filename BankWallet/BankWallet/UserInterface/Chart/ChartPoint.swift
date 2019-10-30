import Foundation

struct ChartPointPosition {
    let timestamp: TimeInterval
    let value: Decimal

    init(timestamp: TimeInterval, value: Decimal) {
        self.timestamp = timestamp
        self.value = value
    }
}

extension ChartPointPosition: Equatable {

    public static func ==(lhs: ChartPointPosition, rhs: ChartPointPosition) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.value == rhs.value
    }

}
