import UIKit

class LimitTextLayer: CATextLayer {
    private let verticalMargin: CGFloat = .margin1x

    func refresh(configuration: ChartConfiguration, insets: UIEdgeInsets, chartFrame: ChartFrame) {
        guard !bounds.isEmpty else {
            return
        }
        self.sublayers?.removeAll()

        let deltaY = (bounds.height - insets.height).decimalValue / chartFrame.height

        let maxHeight = deltaY * (chartFrame.top - chartFrame.maxValue)
        let maxPointOffsetY = floor(insets.top + maxHeight.cgFloatValue + verticalMargin)

        let minHeight = deltaY * (chartFrame.top - chartFrame.minValue)
        var minPointOffsetY = floor(insets.top + minHeight.cgFloatValue + verticalMargin)

        if minPointOffsetY > bounds.height - insets.height - UIFont.appSubhead1.lineHeight - verticalMargin {      // maxValue can't fit under line
            minPointOffsetY = insets.top + minHeight.cgFloatValue - verticalMargin - configuration.limitTextFont.lineHeight
        }

        let formatter = ValueScaleHelper.formatter
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = max(0, chartFrame.scale)

        let maxTextLayer = CATextLayer()
        maxTextLayer.contentsScale = UIScreen.main.scale
        maxTextLayer.frame = CGRect(x: insets.left + configuration.limitTextLeftMargin, y: maxPointOffsetY, width: bounds.width - configuration.limitTextLeftMargin - insets.width, height: configuration.limitTextFont.lineHeight)
        maxTextLayer.foregroundColor = configuration.limitTextColor.cgColor
        maxTextLayer.font = CTFontCreateWithFontDescriptor(configuration.limitTextFont.fontDescriptor, configuration.limitTextFont.pointSize, nil)
        maxTextLayer.fontSize = configuration.limitTextFont.pointSize

        maxTextLayer.string = formatter.string(from: (chartFrame.maxValue) as NSNumber)
        maxTextLayer.removeAllAnimations()

        addSublayer(maxTextLayer)

        let minTextLayer = CATextLayer()
        minTextLayer.contentsScale = UIScreen.main.scale
        minTextLayer.frame = CGRect(x: insets.left + configuration.limitTextLeftMargin, y: minPointOffsetY, width: bounds.width - configuration.limitTextLeftMargin - insets.width, height: configuration.limitTextFont.lineHeight)
        minTextLayer.foregroundColor = configuration.limitTextColor.cgColor
        minTextLayer.font = CTFontCreateWithFontDescriptor(configuration.limitTextFont.fontDescriptor, configuration.limitTextFont.pointSize, nil)
        minTextLayer.fontSize = configuration.limitTextFont.pointSize
        minTextLayer.string = formatter.string(from: (chartFrame.minValue) as NSNumber)
        minTextLayer.removeAllAnimations()

        addSublayer(minTextLayer)
    }

}
