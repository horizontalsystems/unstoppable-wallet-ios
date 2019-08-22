import UIKit

class ValueTextLayer: CATextLayer {

    func refresh(configuration: ChartConfiguration, insets: UIEdgeInsets, chartFrame: ChartFrame) {
        guard !bounds.isEmpty else {
            return
        }

        self.sublayers?.removeAll()

        let delta = (bounds.height - insets.height) / CGFloat(configuration.gridHorizontalLineCount - 1)
        let valueDelta = (chartFrame.top - chartFrame.bottom) / Decimal(configuration.gridHorizontalLineCount - 1)

        let formatter = ChartScaleHelper.formatter
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = chartFrame.scale

        for i in 0..<(configuration.gridHorizontalLineCount - 1) {
            let height = floor(insets.top + delta * CGFloat(i)) + configuration.gridTextMargin

            let textLayer = CATextLayer()
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.frame = CGRect(x: insets.left + configuration.gridTextMargin, y: height, width: bounds.width - configuration.gridTextMargin - insets.width, height: configuration.gridTextFont.lineHeight)
            textLayer.foregroundColor = configuration.gridTextColor.cgColor
            textLayer.font = CTFontCreateWithName(configuration.gridTextFont.fontName as CFString, configuration.gridTextFont.pointSize, nil)
            textLayer.fontSize = configuration.gridTextFont.pointSize

            textLayer.string = formatter.string(from: (chartFrame.top - Decimal(i) * valueDelta) as NSNumber)
                    //String(format: "%.\(chartFrame.scale)f", Float(truncating: (chartFrame.top - Decimal(i) * valueDelta) as NSNumber))
            textLayer.removeAllAnimations()

            addSublayer(textLayer)
        }

        removeAllAnimations()
    }

}
