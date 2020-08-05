import Foundation
import Chart
import LanguageKit
import CurrencyKit
import ThemeKit

extension ChartConfiguration {

    static var fullChart: ChartConfiguration {
        ChartConfiguration().applyColors()
    }

    @discardableResult private func applyColors() -> Self {
        borderColor = .themeSteel20
        backgroundColor = .clear
        selectedColor = .themeNina
        limitLinesColor = .themeNina
        limitTextColor = .themeNina
        limitTextFont = .caption
        verticalLinesColor = .themeSteel20
        volumeBarsFillColor = .themeSteel20
        timelineTextColor = .themeGray
        timelineFont = .caption
        touchLineColor = .themeNina
        emaShortColor = UIColor.themeStronbuy.withAlphaComponent(0.5)
        emaLongColor = UIColor.themeJacob.withAlphaComponent(0.5)
        macdSignalColor = UIColor.themeStronbuy.withAlphaComponent(0.5)
        macdColor = UIColor.themeJacob.withAlphaComponent(0.5)
        macdPositiveColor = UIColor.themeGreenD.withAlphaComponent(0.5)
        macdNegativeColor = UIColor.themeRedD.withAlphaComponent(0.5)
        rsiLineColor = UIColor.themeJacob.withAlphaComponent(0.5)

        macdTextColor = .themeGray
        macdTextFont = .caption

        return self
    }

}
