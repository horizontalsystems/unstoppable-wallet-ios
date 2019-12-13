import Foundation

extension ChartConfiguration {

    static var balanceChart: ChartConfiguration {
        let configuration = ChartConfiguration()

        configuration.showGrid = false
        configuration.showLimitValues = false

        return configuration
    }

    static func fullChart(currency: Currency) -> ChartConfiguration {
        let configuration = ChartConfiguration()

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.currencySymbol = currency.symbol

        configuration.limitTextFormatter = formatter
        return configuration
    }

}
