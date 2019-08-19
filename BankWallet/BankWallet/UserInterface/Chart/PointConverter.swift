import UIKit

struct ChartFrame {
    public static let zero: ChartFrame = ChartFrame(left: 0, right: 0, top: 0, bottom: 0, scale: 0)

    let left: TimeInterval
    let right: TimeInterval
    let top: Decimal
    let bottom: Decimal
    let scale: Int

    var width: TimeInterval { return max(0, right - left) }
    var height: Decimal { return max(0, top - bottom) }

}

class PointConverter {

    func convert(chartPoint: ChartPoint, viewBounds: CGRect, chartFrame: ChartFrame, retinaShift: Bool) -> CGPoint {
        guard chartFrame.height != 0, chartFrame.width != 0 else {
            return .zero
        }

        let deltaX = (viewBounds.width) / CGFloat(chartFrame.width)
        let deltaY = (viewBounds.height) / CGFloat(truncating: chartFrame.height as NSNumber)

        let pointOffsetX = CGFloat(chartPoint.timestamp - chartFrame.left) * deltaX
        let pointOffsetY = CGFloat(truncating: (chartPoint.value - chartFrame.bottom) as NSNumber) * deltaY

        let x: CGFloat = pointOffsetX
        let y: CGFloat = floor(viewBounds.height - pointOffsetY) + (retinaShift ? 0.5 / UIScreen.main.scale : 0)
        return CGPoint(x: x, y: y)
    }

}
