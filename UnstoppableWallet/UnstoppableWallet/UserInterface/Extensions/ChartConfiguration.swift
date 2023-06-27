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
        baseChart
    }

    static var baseBarChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyBase().applyBars()
    }

    static var volumeBarChart: ChartConfiguration {
        baseBarChart.applyVolume()
    }

    static var smallPreviewChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyPreview(height: 25, curveWidth: 1)
    }

    static var previewChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyPreview(height: 60)
    }

    static var previewBarChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyPreview(height: 60).applyBarsPreview()
    }

    @discardableResult private func applyBase() -> Self {
        mainHeight = 160
        timelineHeight = 0

        showBorders = false
        showIndicatorArea = false
        showVerticalLines = false

        curveWidth = 2
        curvePadding = UIEdgeInsets(top: 20, left: .margin8, bottom: 20, right: .margin8)
        indicatorAreaPadding = UIEdgeInsets(top: 8, left: .margin8, bottom: 0, right: .margin8)

        return self
    }

    @discardableResult private func applyPreview(height: CGFloat, curveWidth: CGFloat = 2) -> Self {
        mainHeight = height
        indicatorHeight = 0
        timelineHeight = 0
        self.curveWidth = curveWidth
        curvePadding = UIEdgeInsets(top: .margin2, left: 0, bottom: 10, right: 0)

        showBorders = false
        showIndicatorArea = false
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
        curvePadding = UIEdgeInsets(top: 2, left: 2, bottom: 4, right: 2)

        return self
    }

    @discardableResult private func applyVolume() -> Self {
        indicatorHeight = 44
        showIndicatorArea = true

        return self
    }

    @discardableResult private func applyColors(trendIgnore: Bool = false) -> Self {
        borderColor = .themeSteel20
        backgroundColor = .clear

        trendUpColor = UIColor.themeGreenD
        trendDownColor = UIColor.themeRedD
        pressedColor = .themeNina
        outdatedColor = .themeJacob

        trendUpGradient = [UIColor](repeatElement(UIColor(hex: 0x13D670), count: 3))
        trendDownGradient = [UIColor(hex: 0x7413D6), UIColor(hex: 0x7413D6), UIColor(hex: 0xFF0303)]
        pressedGradient = [UIColor](repeatElement(.themeLeah, count: 3))
        neutralGradient = [UIColor](repeatElement(UIColor(hex: 0xFFa800), count: 3))
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

        return self
    }

}

extension ChartIndicator.LineConfiguration {

    static public var dominance: Self {
        Self(color: ChartColor(.themeYellowD.withAlphaComponent(0.5)), width: 1)
    }

    static public var dominanceId: String {
        let indicator = PrecalculatedIndicator(id: MarketGlobalModule.dominance, enabled: true, values: [], configuration: dominance)
        return indicator.json
    }

}