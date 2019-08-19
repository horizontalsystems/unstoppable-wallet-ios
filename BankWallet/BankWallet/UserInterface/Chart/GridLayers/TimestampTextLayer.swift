import UIKit

class TimestampTextLayer: CATextLayer {

    func refresh(configuration: ChartConfiguration, insets: UIEdgeInsets, chartFrame: ChartFrame, timestamps: [TimeInterval]) {
        guard !bounds.isEmpty else {
            return
        }

        self.sublayers?.removeAll()

        let width = bounds.width - insets.width
        let delta = width / CGFloat(chartFrame.width)

        for timestamp in timestamps {
            var pointOffsetX = CGFloat(timestamp - chartFrame.left) * delta
            if pointOffsetX < configuration.gridNonVisibleLineDeltaX {
                pointOffsetX = 0
            } else if abs(width - pointOffsetX) < configuration.gridNonVisibleLineDeltaX {
                pointOffsetX = width
            }

            let text = TimestampFormatter.text(timestamp: timestamp, type: configuration.chartType)
            let textSize = (text as NSString).size(withAttributes: [NSAttributedString.Key.font: configuration.gridTextFont])

            let textLayer = CATextLayer()
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.frame = CGRect(x: insets.left + pointOffsetX, y: configuration.gridTextMargin, width: textSize.width, height: textSize.height)
            textLayer.foregroundColor = configuration.gridTextColor.cgColor
            textLayer.font = CTFontCreateWithName(configuration.gridTextFont.fontName as CFString, configuration.gridTextFont.pointSize, nil)
            textLayer.fontSize = configuration.gridTextFont.pointSize

            textLayer.string = text
            textLayer.removeAllAnimations()

            addSublayer(textLayer)
        }
        removeAllAnimations()
    }

}
