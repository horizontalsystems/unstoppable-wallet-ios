import UIKit

class LimitLinesLayer: CAShapeLayer {

    func refresh(configuration: ChartConfiguration, pointConverter: IPointConverter, insets: UIEdgeInsets, chartFrame: ChartFrame) {
        guard !bounds.isEmpty else {
            return
        }
        self.sublayers?.removeAll()

        let horizontalPath = UIBezierPath()

        let frameBounds = bounds.inset(by: insets)
        let maxPointOffsetY = pointConverter.convert(chartPoint: ChartPoint(timestamp: 0, value: chartFrame.maxValue),
                viewBounds: frameBounds, chartFrame: chartFrame, retinaShift: false).y
        let minPointOffsetY = pointConverter.convert(chartPoint: ChartPoint(timestamp: 0, value: chartFrame.minValue),
                viewBounds: frameBounds, chartFrame: chartFrame, retinaShift: false).y

        horizontalPath.move(to: CGPoint(x: insets.left, y: maxPointOffsetY))
        horizontalPath.addLine(to: CGPoint(x: bounds.width - insets.right, y: maxPointOffsetY))

        horizontalPath.move(to: CGPoint(x: insets.left, y: minPointOffsetY))
        horizontalPath.addLine(to: CGPoint(x: bounds.width - insets.right, y: minPointOffsetY))

        horizontalPath.move(to: CGPoint(x: insets.left, y: maxPointOffsetY))

        horizontalPath.close()

        strokeColor = configuration.limitColor.cgColor
        lineDashPattern = [2, 2]

        let scaleInt = Int(UIScreen.main.scale)
        let pxCount =  scaleInt / 2 + scaleInt % 2

        lineWidth = CGFloat(pxCount) / UIScreen.main.scale      // round half scale to top ( 1/2 for 2x, 2/3 for 3x...)
        path = horizontalPath.cgPath

        removeAllAnimations()
    }

}
