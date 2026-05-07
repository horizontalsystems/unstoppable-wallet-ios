import Chart

import UIKit

extension ChartConfiguration {
    static var baseChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyBase()
    }

    static var chartWithIndicatorArea: ChartConfiguration {
        baseChart.applyIndicatorArea()
    }

    static var marketCapChart: ChartConfiguration {
        baseChart
    }

    static var baseBarChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyBase().applyBars()
    }

    static var baseHistogramChart: ChartConfiguration {
        ChartConfiguration().applyColors().applyBase().applyHistogram()
    }

    static var volumeBarChart: ChartConfiguration {
        baseBarChart.applyIndicatorArea()
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

    @discardableResult private func clearGradients() -> Self {
        let clear = [UIColor.clear]
        trendUpGradient = clear
        trendDownGradient = clear
        pressedGradient = clear
        neutralGradient = clear
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

        clearGradients()

        return self
    }

    @discardableResult private func applyBars() -> Self {
        curveType = .bars
        curveBottomInset = 18

        clearGradients()

        return self
    }

    @discardableResult private func applyHistogram() -> Self {
        curveType = .histogram
        curveBottomInset = 18

        indicatorHeight = 0
        timelineHeight = 0

        redrawOnResize = true

        clearGradients()

        return self
    }

    @discardableResult private func applyBarsPreview() -> Self {
        curveType = .bars
        curvePadding = UIEdgeInsets(top: 2, left: 2, bottom: 4, right: 2)

        return self
    }

    @discardableResult private func applyIndicatorArea() -> Self {
        indicatorHeight = 44
        showIndicatorArea = true

        return self
    }

    @discardableResult private func applyColors(trendIgnore _: Bool = false) -> Self {
        borderColor = .themeBlade
        backgroundColor = .clear

        trendUpColor = UIColor.themeGreenD
        trendDownColor = UIColor.themeRedD
        pressedColor = .themeNina
        outdatedColor = .themeJacob

        trendUpGradient = [UIColor](repeatElement(UIColor(hex: 0x13D670), count: 3))
        trendDownGradient = [UIColor(hex: 0x7413D6), UIColor(hex: 0x7413D6), UIColor(hex: 0xFF0303)]
        pressedGradient = [UIColor](repeatElement(.themeLeah, count: 3))
        neutralGradient = [UIColor](repeatElement(UIColor(hex: 0xFFA800), count: 3))
        gradientLocations = [0, 0.05, 1]
        gradientAlphas = [0, 0, 0.3]

        limitLinesColor = .themeBlade
        limitTextColor = .themeNina
        limitTextFont = .caption
        verticalLinesColor = .themeBlade
        volumeBarsFillColor = .themeBlade
        timelineTextColor = .themeGray
        timelineFont = .caption
        touchLineColor = .themeNina
        touchCircleColor = .themeLeah

        return self
    }
}

public extension ChartIndicator.LineConfiguration {
    static var dominance: Self {
        Self(color: ChartColor(.themeYellowD.withAlphaComponent(0.5)), width: 1)
    }

    static var dominanceId: String {
        let indicator = PrecalculatedIndicator(id: MarketGlobalModule.dominance, enabled: true, values: [], configuration: dominance)
        return indicator.json
    }

    static var totalAssets: Self {
        Self(color: ChartColor(.themeNina.withAlphaComponent(0.5)), width: 1)
    }

    static var totalAssetId: String {
        let indicator = PrecalculatedIndicator(id: MarketGlobalModule.totalAssets, enabled: true, values: [], configuration: totalAssets)
        return indicator.json
    }

    static var dailyInflow: Self {
        Self(color: ChartColor(.themeNina.withAlphaComponent(0.5)), width: 1)
    }

    static var dailyInflowId: String {
        let indicator = PrecalculatedIndicator(id: MarketGlobalModule.dailyInflow, enabled: false, values: [], configuration: dailyInflow)
        return indicator.json
    }
}
