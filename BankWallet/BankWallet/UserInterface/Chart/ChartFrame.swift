import Foundation

enum ChartColorType {
    case positive, negative, incomplete
}

struct ChartFrame {
    public static let zero: ChartFrame = ChartFrame(left: 0, right: 0, top: 0, bottom: 0, minValue: 0, maxValue: 0, scale: 0, chartColorType: .incomplete)

    let left: TimeInterval
    let right: TimeInterval
    let top: Decimal
    let bottom: Decimal
    let minValue: Decimal
    let maxValue: Decimal
    let scale: Int
    let chartColorType: ChartColorType

    var width: TimeInterval { max(0, right - left) }
    var height: Decimal { max(0, top - bottom) }

}
