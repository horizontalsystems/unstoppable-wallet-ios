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
        let configuration = ChartConfiguration().applyColors()

        configuration.mainHeight = ChartCell.chartHeight
        configuration.showIndicators = false
        configuration.indicatorHeight = 0
        configuration.timelineHeight = ChartCell.timelineHeight
        configuration.timelineInsets = UIEdgeInsets(top: 4, left: 8, bottom: 0, right: 8)

        return configuration
    }

    static var chartWithDominance: ChartConfiguration {
        let configuration = chartWithoutIndicators
        configuration.showDominance = true

        return configuration
    }

    static var chartPreview: ChartConfiguration {
        let config = ChartConfiguration().applyColors()

        config.mainHeight = 25
        config.indicatorHeight = 0
        config.timelineHeight = 0
        config.curvePadding = UIEdgeInsets(top: .margin2, left: 0, bottom: 10, right: 0)

        config.showBorders = false
        config.showIndicators = false
        config.showLimits = false
        config.showVerticalLines = false
        config.isInteractive = false

        let clear = [UIColor.clear]
        config.trendUpGradient = clear
        config.trendDownGradient = clear
        config.pressedGradient = clear
        config.neutralGradient = clear

        return config
    }

    @discardableResult private func applyColors() -> Self {
        borderColor = .themeSteel20
        backgroundColor = .clear

        trendUpColor = UIColor.themeGreenD
        trendDownColor = UIColor.themeRedD
        pressedColor = .themeNina
        outdatedColor = .themeNina

        trendUpGradient = [UIColor](repeatElement(UIColor(hex: 0x13D670), count: 3))
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
