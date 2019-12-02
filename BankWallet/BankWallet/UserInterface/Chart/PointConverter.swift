import UIKit

class PointConverter: IPointConverter {
    private let percentPadding: CGFloat
    private let pixelsMargin: CGFloat

    init(percentPadding: CGFloat = .zero, pixelsMargin: CGFloat = .zero) {
        self.percentPadding = percentPadding
        self.pixelsMargin = pixelsMargin
    }

    func convert(chartPoint: ChartPoint, viewBounds: CGRect, chartFrame: ChartFrame, retinaShift: Bool) -> CGPoint {
        guard chartFrame.height != 0, chartFrame.width != 0 else {
            return .zero
        }

        let verticalMargin = percentPadding * viewBounds.height + pixelsMargin
        let deltaX = (viewBounds.width) / CGFloat(chartFrame.width)
        let deltaY = (viewBounds.height - 2 * verticalMargin) / CGFloat(truncating: chartFrame.height as NSNumber)

        let pointOffsetX = CGFloat(chartPoint.timestamp - chartFrame.left) * deltaX
        let pointOffsetY = CGFloat(truncating: (chartPoint.value - chartFrame.bottom) as NSNumber) * deltaY

        let x: CGFloat = pointOffsetX
        let y: CGFloat = floor(viewBounds.height - pointOffsetY - verticalMargin) + (retinaShift ? 0.5 / UIScreen.main.scale : 0)
        return CGPoint(x: x, y: y)
    }

}
