import Foundation

class ValueFormatter {
    static let instance = ValueFormatter()

    static private let fractionDigits = 8

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = ValueFormatter.fractionDigits
        formatter.roundingMode = .ceiling
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.roundingMode = .ceiling
        return formatter
    }()

    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = ValueFormatter.fractionDigits
        formatter.numberStyle = .decimal
        formatter.roundingMode = .ceiling
        formatter.groupingSeparator = ""
        return formatter
    }()

    let parseFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    func format(coinValue: CoinValue, explicitSign: Bool = false) -> String? {
        let value = explicitSign ? abs(coinValue.value) : coinValue.value

        coinFormatter.minimumFractionDigits = value > 0 ? 2 : 0

        guard let formattedValue = coinFormatter.string(from: value as NSNumber) else {
            return nil
        }

        var result = "\(formattedValue) \(coinValue.coinCode)"

        if explicitSign {
            let sign = coinValue.value < 0 ? "-" : "+"
            result = "\(sign) \(result)"
        }

        return result
    }

    func format(currencyValue: CurrencyValue, approximate: Bool = false, shortFractionLimit: Double? = nil) -> String? {
        var value = currencyValue.value

        let formatter = currencyFormatter
        formatter.currencyCode = currencyValue.currency.code
        formatter.currencySymbol = currencyValue.currency.symbol

        if let limit = shortFractionLimit {
            formatter.maximumFractionDigits = abs(value) > limit ? 0 : 2
        } else {
            formatter.maximumFractionDigits = 2
        }

        if approximate {
            value = abs(value)
        }

        guard var result = formatter.string(from: value as NSNumber) else {
            return nil
        }

        if approximate {
            result = "~ \(result)"
        }

        return result
    }

    func format(amount: Double) -> String? {
        return amountFormatter.string(from: amount as NSNumber)
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
