import UIKit
import Chart
import LanguageKit
import CurrencyKit
import ThemeKit

extension ChartConfiguration {

    static var baseChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyBase()
    }

    static var coinChart: ChartConfiguration {
        baseChart.applyVolume()
    }

    static var marketCapChart: ChartConfiguration {
        baseChart.applyDominance()
    }

    static var baseBarChart: ChartConfiguration {
        ChartConfiguration().applyColors(trendIgnore: true).applyBase().applyBars()
    }

    static var volumeBarChart: ChartConfiguration {
        baseBarChart.applyVolume()
    }

    static var smallPreviewChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyPreview(height: 25)
    }

    static var previewChart: ChartConfiguration {
        ChartConfiguration().applyColors(trendIgnore: true).applyPreview(height: 60)
    }

    static var previewBarChart: ChartConfiguration {
        ChartConfiguration().applyColors(trendIgnore: true).applyPreview(height: 60).applyBarsPreview()
    }

    @discardableResult private func applyBase() -> Self {
        mainHeight = 160
        timelineHeight = 0

        showBorders = false
        showIndicators = false
        showVerticalLines = false

        curveWidth = 2
        curvePadding = UIEdgeInsets(top: 20, left: .margin8, bottom: 20, right: .margin8)
        volumeBarsInsets = UIEdgeInsets(top: 8, left: .margin8, bottom: 0, right: .margin8)

        return self
    }

    @discardableResult private func applyPreview(height: CGFloat) -> Self {
        mainHeight = height
        indicatorHeight = 0
        timelineHeight = 0
        curvePadding = UIEdgeInsets(top: .margin2, left: 0, bottom: 10, right: 0)

        showBorders = false
        showIndicators = false
        showLimits = false
        showVerticalLines = false
        isInteractive = false

        let clear = [UIColor.clear]
        trendUpGradient = clear
        trendDownGradient = clear
        pressedGradient = clear
        neutralGradient = clear

        return self
    }

    @discardableResult private func applyBars() -> Self {
        curveType = .bars
        curveBottomInset = 18

        trendUpGradient =  [.clear]
        trendDownGradient =  [.clear]
        pressedGradient =  [.clear]
        neutralGradient =  [.clear]

        return self
    }

    @discardableResult private func applyBarsPreview() -> Self {
        curveType = .bars
        curveWidth = 2
        curvePadding = UIEdgeInsets(top: 2, left: 2, bottom: 4, right: 2)

        return self
    }

    @discardableResult private func applyVolume() -> Self {
        indicatorHeight = 44
        showIndicators = true

        return self
    }

    @discardableResult private func applyDominance() -> Self {
        showDominance = true

        return self
    }

    @discardableResult private func applyColors(trendIgnore: Bool = false) -> Self {
        borderColor = .themeSteel20
        backgroundColor = .clear

        trendUpColor = trendIgnore ? UIColor.themeJacob : UIColor.themeGreenD
        trendDownColor = trendIgnore ? UIColor.themeJacob : UIColor.themeRedD
        pressedColor = .themeNina
        outdatedColor = .themeNina

        trendUpGradient = [UIColor](repeatElement(UIColor(hex: trendIgnore ? 0xFFa800 : 0x13D670), count: 3))
        trendDownGradient = [UIColor(hex: 0x7413D6), UIColor(hex: 0x7413D6), UIColor(hex: 0xFF0303)]
        pressedGradient = [UIColor](repeatElement(.themeLeah, count: 3))
        neutralGradient = [UIColor](repeatElement(.themeGray50, count: 3))
        gradientLocations = [0, 0.05, 1]
        gradientAlphas = [0, 0, 0.3]

        limitLinesColor = .themeSteel20
        limitTextColor = .themeNina
        limitTextFont = .caption
        verticalLinesColor = .themeSteel10
        volumeBarsFillColor = .themeSteel20
        timelineTextColor = .themeGray
        timelineFont = .caption
        touchLineColor = .themeNina
        touchCircleColor = .themeLeah
        emaShortColor = UIColor.themeStronbuy.withAlphaComponent(0.5)
        emaLongColor = UIColor.themeJacob.withAlphaComponent(0.5)
        macdSignalColor = UIColor.themeStronbuy.withAlphaComponent(0.5)
        macdColor = UIColor.themeJacob.withAlphaComponent(0.5)
        macdPositiveColor = UIColor.themeGreenD.withAlphaComponent(0.5)
        macdNegativeColor = UIColor.themeRedD.withAlphaComponent(0.5)
        rsiLineColor = UIColor.themeJacob.withAlphaComponent(0.5)

        dominanceLineColor = UIColor.themeJacob.withAlphaComponent(0.5)

        macdTextColor = .themeGray
        macdTextFont = .caption

        return self
    }

}
