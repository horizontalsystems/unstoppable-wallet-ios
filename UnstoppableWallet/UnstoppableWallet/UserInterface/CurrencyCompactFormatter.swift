import Foundation
import CurrencyKit

class CurrencyCompactFormatter {
    private static let postfixes = ["chart.market_cap.thousand", "chart.market_cap.million", "chart.market_cap.billion", "chart.market_cap.trillion"]
    public static let instance = CurrencyCompactFormatter()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static func compactData(value: Decimal) -> (value: Decimal, postfix: String?) {
        let ten: Decimal = 10

        var index = 1
        var power: Decimal = 1000
        while abs(value) >= power {
            power = pow(ten, (index + 1) * 3)
            index += 1
            if index > postfixes.count {
                break
            }
        }
        let postfix: String? = index < 2 ? nil : CurrencyCompactFormatter.postfixes[index - 2]
        return (value: value / pow(ten, (index - 1) * 3), postfix: postfix)
    }

    public func format(currency: Currency, value: Decimal?, fractionMaximumFractionDigits: Int = 1, alwaysSigned: Bool = false) -> String? {
        guard let value = value else {
            return nil
        }
        let data = CurrencyCompactFormatter.compactData(value: value)

        currencyFormatter.currencyCode = currency.code
        currencyFormatter.currencySymbol = currency.symbol
        currencyFormatter.maximumFractionDigits = fractionMaximumFractionDigits

        let universalValue = alwaysSigned ? abs(data.value) : data.value
        guard var formattedValue = currencyFormatter.string(from: universalValue as NSNumber) else {
            return nil
        }

        if alwaysSigned {
            let sign = data.value.isSignMinus ? "-" : "+"
            formattedValue = sign + formattedValue
        }
        return data.postfix?.localized(formattedValue) ?? formattedValue
    }

    public func format(symbol: String, value: Decimal?, fractionMaximumFractionDigits: Int = 1) -> String? {
        guard let value = value else {
            return nil
        }

        currencyFormatter.currencyCode = ""
        currencyFormatter.currencySymbol = ""
        currencyFormatter.maximumFractionDigits = fractionMaximumFractionDigits

        let data = CurrencyCompactFormatter.compactData(value: value)

        guard let formattedValue = currencyFormatter.string(from: data.value as NSNumber)?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }

        return (data.postfix?.localized(formattedValue) ?? formattedValue) + " " + symbol
    }

}
