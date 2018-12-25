import Foundation

class ValueFormatter {
    static let instance = ValueFormatter()

    static private let fractionDigits = 8

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = ValueFormatter.fractionDigits
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = ValueFormatter.fractionDigits
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    let parseFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    func format(coinValue: CoinValue) -> String? {
        coinFormatter.minimumFractionDigits = coinValue.value == 0 ? 2 : 0

        guard let formattedValue = coinFormatter.string(from: abs(coinValue.value) as NSNumber) else {
            return nil
        }

        var result = "\(formattedValue) \(coinValue.coinCode)"

        if coinValue.value < 0 {
            result = "- \(result)"
        }

        return result
    }

    func format(currencyValue: CurrencyValue, shortFractionLimit: Double? = nil) -> String? {
        let absoluteValue = abs(currencyValue.value)

        let formatter = currencyFormatter
        formatter.currencyCode = currencyValue.currency.code
        formatter.currencySymbol = currencyValue.currency.symbol

        if let limit = shortFractionLimit {
            formatter.maximumFractionDigits = absoluteValue > limit ? 0 : 2
        } else {
            formatter.maximumFractionDigits = 2
        }

        guard var result = formatter.string(from: absoluteValue as NSNumber) else {
            return nil
        }

        if currencyValue.value < 0 {
            result = "- \(result)"
        }

        return result
    }

    func format(amount: Double) -> String? {
        return amountFormatter.string(from: amount as NSNumber)
    }

    var decimalSeparator: String {
        return amountFormatter.decimalSeparator
    }

    func formattedInput(string: String?) -> String? {
        let stringNumber = "0\(string ?? "")"
        let number = parseFormatter.number(from: stringNumber) as? Double
        if let number = number {
            return format(amount: number)
        }
        return nil
    }

}
