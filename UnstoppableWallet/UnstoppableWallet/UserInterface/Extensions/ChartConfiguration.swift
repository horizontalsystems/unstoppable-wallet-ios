import Foundation
import Chart
import LanguageKit
import CurrencyKit
import ThemeKit

extension ChartConfiguration {

    static var fullChart: ChartConfiguration {
        ChartConfiguration().applyColors()
    }

    static var chartWithoutIndicators: ChartConfiguration {
        let configuration = ChartConfiguration().applyColors()
        configuration.showIndicators = false
        configuration.timelineInsets = UIEdgeInsets(top: 4, left: 8, bottom: 0, right: 8)

        return configuration
    }

    static var chartWithDominance: ChartConfiguration {
        let configuration = chartWithoutIndicators
        configuration.showDominance = true

        return configuration
    }

    static var smallChart: ChartConfiguration {
        let config = ChartConfiguration().applyColors()

        config.mainHeight = .margin32 + .margin2
        config.indicatorHeight = 0
        config.timelineHeight = 0
        config.curvePadding = UIEdgeInsets(top: .margin2, left: 0, bottom: 10, right: 0)

        config.showBorders = false
        config.showIndicators = false
        config.showLimits = false
        config.showVerticalLines = false
        config.isInteractive = false

        return config
    }

    @discardableResult private func applyColors() -> Self {
        borderColor = .themeSteel20
        backgroundColor = .clear

        trendUpColor = UIColor.themeGreenD
        trendDownColor = UIColor.themeRedD
        pressedColor = .themeNina
        outdatedColor = .themeNina

        trendUpGradient = [UIColor(hex: 0x416BFF), UIColor(hex: 0x13D670)]
        trendDownGradient = [UIColor(hex: 0x7413D6), UIColor(hex: 0xFF0303)]
        pressedGradient = [UIColor.themeOz, UIColor.themeOz]
        neutralGradient = [UIColor.themeGray50, UIColor.themeGray50]
        gradientAlphas = [0.05, 0.3]

        limitLinesColor = .themeNina
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
