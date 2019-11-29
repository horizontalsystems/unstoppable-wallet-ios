import UIKit

class LimitLinesLayer: CAShapeLayer {

    func refresh(configuration: ChartConfiguration, insets: UIEdgeInsets, chartFrame: ChartFrame) {
        guard !bounds.isEmpty else {
            return
        }
        self.sublayers?.removeAll()

        let deltaY = (bounds.height - insets.height).decimalValue / chartFrame.height
        let minHeight = deltaY * (chartFrame.top - chartFrame.minValue)
        let maxHeight = deltaY * (chartFrame.top - chartFrame.maxValue)

        let horizontalPath = UIBezierPath()

        let maxPointOffsetY = floor(insets.top + maxHeight.cgFloatValue)
        horizontalPath.move(to: CGPoint(x: insets.left, y: maxPointOffsetY))
        horizontalPath.addLine(to: CGPoint(x: bounds.width - insets.right, y: maxPointOffsetY))

        let minPointOffsetY = floor(insets.top + minHeight.cgFloatValue)
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
