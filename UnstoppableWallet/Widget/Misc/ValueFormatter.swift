import Foundation

enum ValueFormatter {
    private static let rawFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static func fractionZeroCount(value: Decimal, maxCount: Int) -> Int {
        guard value > 0, value < 1 else {
            return 0
        }

        for count in 0 ..< maxCount {
            if value * pow(10, count + 1) >= 1 {
                return count
            }
        }

        return maxCount
    }

    private static func transformedFull(value: Decimal, maxDigits: Int, minDigits: Int = 0) -> (value: Decimal, digits: Int) {
        let value = abs(value)
        let digits: Int

        switch value {
        case 0:
            digits = 0

        case 0 ..< 1:
            let zeroCount = fractionZeroCount(value: value, maxCount: maxDigits - 1)
            digits = min(maxDigits, zeroCount + 4)

        case 1 ..< 1.01:
            digits = 4

        case 1.01 ..< 1.1:
            digits = 3

        case 1.1 ..< 20:
            digits = 2

        case 20 ..< 200:
            digits = 1

        default:
            digits = 0
        }

        return (value: value, digits: max(digits, minDigits))
    }

    private static func decorated(string: String, symbol: String? = nil, signValue: Decimal? = nil) -> String {
        var string = string

        if let symbol {
            string = "\(string) \(symbol)"
        }

        if let signValue {
            var sign = ""
            if !signValue.isZero {
                sign = signValue.isSignMinus ? "-" : "+"
            }
            string = "\(sign)\(string)"
        }

        return string
    }

    private static func formattedCurrency(value: Decimal, digits: Int, code: String, symbol: String) -> String? {
        currencyFormatter.currencyCode = code
        currencyFormatter.currencySymbol = symbol
        currencyFormatter.internationalCurrencySymbol = symbol

        guard let pattern = currencyFormatter.string(from: 1 as NSDecimalNumber) else {
            return nil
        }

        rawFormatter.maximumFractionDigits = digits

        guard let string = rawFormatter.string(from: value as NSDecimalNumber) else {
            return nil
        }

        return pattern.replacingOccurrences(of: "1", with: decorated(string: string))
    }

    static func format(percentValue: Decimal, showSign: Bool = true) -> String? {
        let (transformedValue, digits) = transformedFull(value: percentValue, maxDigits: 2)

        rawFormatter.maximumFractionDigits = digits

        guard let string = rawFormatter.string(from: transformedValue as NSDecimalNumber) else {
            return nil
        }

        return decorated(string: string, signValue: showSign ? percentValue : nil) + "%"
    }

    static func format(currency: Currency, value: Decimal, showSign: Bool = false) -> String? {
        let (transformedValue, digits) = transformedFull(value: value, maxDigits: 18)

        guard let string = formattedCurrency(value: transformedValue, digits: digits, code: currency.code, symbol: currency.symbol) else {
            return nil
        }

        return decorated(string: string, signValue: showSign ? value : nil)
    }
}
