import Foundation
import Chart
import LanguageKit
import CurrencyKit

extension ChartConfiguration {

    static var balanceChart: ChartConfiguration {
        let configuration = ChartConfiguration()
        configuration.setCryptoColors()

        configuration.showGrid = false
        configuration.showLimitValues = false

        return configuration
    }

    static func fullChart(currency: Currency) -> ChartConfiguration {
        let configuration = ChartConfiguration()
        configuration.setCryptoColors()

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = currency.code
        currencyFormatter.currencySymbol = currency.symbol

        let dateFormatter = DateFormatter()
        dateFormatter.locale = LanguageManager.shared.currentLocale

        configuration.limitTextFormatter = currencyFormatter
        configuration.dateFormatter = dateFormatter
        return configuration
    }

    private func setCryptoColors() {
        curvePositiveColor = .themeRemus
        curveNegativeColor = .themeLucian
        curveIncompleteColor = .themeGray50

        gradientPositiveColor = .themeRemus
        gradientNegativeColor = .themeLucian
        gradientIncompleteColor = .themeGray50

        limitColor = .themeNina

        gridColor = .themeSteel20
        gridTextColor = .themeGray

        limitTextFont = .subhead1
        limitTextColor = .themeLeah

        selectedIndicatorColor = .themeOz
        selectedCurveColor = .themeOz
        selectedGradientColor = .themeOz

        volumeBarColor = .themeSteel20
    }

}
