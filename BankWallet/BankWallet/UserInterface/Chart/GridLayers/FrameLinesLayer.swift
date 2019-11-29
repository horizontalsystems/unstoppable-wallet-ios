import UIKit

class FrameLinesLayer: CAShapeLayer {

    func refresh(configuration: ChartConfiguration, insets: UIEdgeInsets) {
        guard !bounds.isEmpty else {
            return
        }

        let path = UIBezierPath()
        let edgeOffset = 0.5 / UIScreen.main.scale

        let width = floor(bounds.width - insets.right)
        let height = floor(bounds.height - insets.bottom)

        // add top line
        path.move(to: CGPoint(x: insets.left + edgeOffset, y: insets.top + edgeOffset))
        path.addLine(to: CGPoint(x: width + edgeOffset, y: insets.top + edgeOffset))

        // add left line
        path.move(to: CGPoint(x: insets.left + edgeOffset, y: insets.top + edgeOffset))
        path.addLine(to: CGPoint(x: insets.left + edgeOffset, y: height  - edgeOffset))

        // add bottom line
        path.move(to: CGPoint(x: insets.left + edgeOffset, y: height - edgeOffset))
        path.addLine(to: CGPoint(x: width + edgeOffset, y: height - edgeOffset))


        // add right line
        path.move(to: CGPoint(x: width + edgeOffset, y: height - edgeOffset))
        path.addLine(to: CGPoint(x: width + edgeOffset, y: insets.top + edgeOffset))

        path.move(to: CGPoint(x: insets.left, y: insets.top + edgeOffset))
        path.close()

        strokeColor = configuration.gridColor.cgColor
        lineWidth = 1 / UIScreen.main.scale
        self.path = path.cgPath

        removeAllAnimations()
    }

}
