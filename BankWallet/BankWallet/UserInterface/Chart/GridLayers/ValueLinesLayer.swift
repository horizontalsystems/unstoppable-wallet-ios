import UIKit

class ValueLinesLayer: CAShapeLayer {

    func refresh(configuration: ChartConfiguration, insets: UIEdgeInsets) {
        guard !bounds.isEmpty else {
            return
        }

        let edgeOffset: CGFloat = 0.5 / UIScreen.main.scale
        let deltaY = floor(bounds.height - insets.height) / CGFloat(configuration.gridHorizontalLineCount - 1)

        let horizontalPath = UIBezierPath()
        let lastLineIndex = configuration.gridHorizontalLineCount - 1
        for i in 0..<configuration.gridHorizontalLineCount {
            let pointOffsetY = insets.top + floor(deltaY * CGFloat(i)) + edgeOffset * (i == lastLineIndex ? 3 : 1)      // last line must be shifted more on 1.5 * scale

            horizontalPath.move(to: CGPoint(x: 0, y: pointOffsetY))
            horizontalPath.addLine(to: CGPoint(x: bounds.width, y: pointOffsetY))
        }
        horizontalPath.close()

        strokeColor = configuration.gridColor.cgColor
        lineWidth = 1 / UIScreen.main.scale
        path = horizontalPath.cgPath

        removeAllAnimations()
    }

}
