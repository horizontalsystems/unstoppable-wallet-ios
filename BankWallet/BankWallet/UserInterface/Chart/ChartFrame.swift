import Foundation

struct ChartFrame {
    public static let zero: ChartFrame = ChartFrame(left: 0, right: 0, top: 0, bottom: 0, scale: 0, positive: true)

    let left: TimeInterval
    let right: TimeInterval
    let top: Decimal
    let bottom: Decimal
    let scale: Int
    let positive: Bool

    var width: TimeInterval { return max(0, right - left) }
    var height: Decimal { return max(0, top - bottom) }

}
