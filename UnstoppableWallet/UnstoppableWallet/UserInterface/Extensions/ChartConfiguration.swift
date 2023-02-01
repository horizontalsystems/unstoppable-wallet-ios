import UIKit
import Chart
import LanguageKit
import CurrencyKit
import ThemeKit

extension ChartConfiguration {

    static var fullChart: ChartConfiguration {
        let configuration = ChartConfiguration().applyColors()

        configuration.mainHeight = ChartCell.chartHeight
        configuration.indicatorHeight = ChartCell.indicatorHeight
        configuration.timelineHeight = ChartCell.timelineHeight

        return configuration
    }

    static var chartWithoutIndicators: ChartConfiguration {
        ChartConfiguration().applyColors().applyChartWithoutIndicators()
    }

    static var cumulativeChartWithoutIndicators: ChartConfiguration {
        ChartConfiguration().applyColors(trendIgnore: true).applyChartWithoutIndicators()
    }

    @discardableResult private func applyChartWithoutIndicators() -> Self {
        mainHeight = ChartCell.chartHeight
        showIndicators = false
        indicatorHeight = 0
        timelineHeight = ChartCell.timelineHeight
        timelineInsets = UIEdgeInsets(top: 4, left: 8, bottom: 0, right: 8)

        return self
    }

    static var chartWithDominance: ChartConfiguration {
        let configuration = chartWithoutIndicators
        configuration.showDominance = true

        return configuration
    }

    static var chartPreview: ChartConfiguration {
        ChartConfiguration().applyColors().applyPreview()
    }

    static var cumulativeChartPreview: ChartConfiguration {
        ChartConfiguration().applyColors(trendIgnore: true).applyPreview()
    }

    @discardableResult private func applyPreview() -> Self {
        mainHeight = 25
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
        dominanceTextColor = .themeJacob
        dominanceDiffPositiveColor = .themeRemus
        dominanceDiffNegativeColor = .themeLucian

        macdTextColor = .themeGray
        macdTextFont = .caption

        return self
    }

}
