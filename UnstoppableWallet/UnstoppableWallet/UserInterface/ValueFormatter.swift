import Foundation

class ValueFormatter {
    static let instance = ValueFormatter()

    private let rawFormatterQueue = DispatchQueue(label: "\(AppConfig.label).value-formatter.raw-formatter", qos: .userInitiated)
    private let currencyFormatterQueue = DispatchQueue(label: "\(AppConfig.label).value-formatter.currency-formatter", qos: .userInitiated)

    private let rawFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .down
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.roundingMode = .down
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private func digitsAndValue(value: Decimal, basePow: Int) -> (Int, Decimal) {
        let digits: Int

        switch value {
        case pow(10, basePow) ..< (2 * pow(10, basePow + 1)): digits = 2
        case (2 * pow(10, basePow + 1)) ..< (2 * pow(10, basePow + 2)): digits = 1
        default: digits = 0
        }

        return (digits, value / pow(10, basePow))
    }

    private func fractionZeroCount(value: Decimal, maxCount: Int) -> Int {
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

    private func edge(_ power: Int) -> Decimal {
        pow(10, power) - (pow(10, power - 3) / 2)
    }

    private func transformedShort(value: Decimal, maxDigits: Int = Int.max) -> (value: Decimal, digits: Int, suffix: String?, tooSmall: Bool) {
        var value = abs(value)
        var suffix: String?
        let digits: Int
        var tooSmall = false

        switch value {
        case 0:
            digits = 0

        case 0 ..< 0.0000_0001:
            digits = 8
            value = 0.0000_0001
            tooSmall = true

        case 0.0000_0001 ..< 1:
            let zeroCount = fractionZeroCount(value: value, maxCount: 8)
            digits = min(maxDigits, zeroCount + 4, 8)

        case 1 ..< 1.01:
            digits = 4

        case 1.01 ..< 1.1:
            digits = 3

        case 1.1 ..< 20:
            digits = 2

        case 20 ..< 200:
            digits = 1

        case 200 ..< 19999.5:
            digits = 0

        case 19999.5 ..< edge(6):
            (digits, value) = digitsAndValue(value: value, basePow: 3)
            suffix = "number.thousand"

        case edge(6) ..< edge(9):
            (digits, value) = digitsAndValue(value: value, basePow: 6)
            suffix = "number.million"

        case edge(9) ..< edge(12):
            (digits, value) = digitsAndValue(value: value, basePow: 9)
            suffix = "number.billion"

        case edge(12) ..< edge(15):
            (digits, value) = digitsAndValue(value: value, basePow: 12)
            suffix = "number.trillion"

        default:
            (digits, value) = digitsAndValue(value: value, basePow: 15)
            suffix = "number.quadrillion"
        }

        return (value: value, digits: digits, suffix: suffix, tooSmall: tooSmall)
    }

    private func transformedFull(value: Decimal, maxDigits: Int, minDigits: Int = 0) -> (value: Decimal, digits: Int) {
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

    private func decorated(string: String, suffix: String? = nil, symbol: String? = nil, signType: SignType = .never, signValue: Decimal, tooSmall: Bool = false) -> String {
        var string = string

        if let suffix {
            string = suffix.localized(string)
        }

        if let symbol {
            string = "\(string) \(symbol)"
        }

        var sign = ""
        if !signValue.isZero {
            sign = signValue.isSignMinus ? "-" : "+"
        }
        switch signType {
        case .never: ()
        case .always: string = "\(sign)\(string)"
        case .auto: if signValue.isSignMinus { string = "\(sign)\(string)" }
        }

        if tooSmall {
            string = "< \(string)"
        }

        return string
    }

    private func formattedCurrency(value: Decimal, digits: Int, code: String, symbol: String, suffix: String? = nil) -> String? {
        let pattern: String? = currencyFormatterQueue.sync {
            currencyFormatter.currencyCode = code
            currencyFormatter.currencySymbol = symbol
            currencyFormatter.internationalCurrencySymbol = symbol
            return currencyFormatter.string(from: 1 as NSDecimalNumber)
        }

        guard let pattern else {
            return nil
        }

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: value as NSDecimalNumber)
        }

        guard let string else {
            return nil
        }

        return pattern.replacingOccurrences(of: "1", with: decorated(string: string, suffix: suffix, signValue: value))
    }
}

extension ValueFormatter {
    func formatShort(value: Decimal) -> String? {
        let (transformedValue, digits, suffix, tooSmall) = transformedShort(value: value)

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: transformedValue as NSDecimalNumber)
        }

        guard let string else {
            return nil
        }

        return decorated(string: string, suffix: suffix, signValue: value, tooSmall: tooSmall)
    }

    func formatShort(value: Decimal, decimalCount: Int, symbol: String? = nil, signType: SignType = .never) -> String? {
        let (transformedValue, digits, suffix, tooSmall) = transformedShort(value: value, maxDigits: decimalCount)

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: transformedValue as NSDecimalNumber)
        }

        guard let string else {
            return nil
        }

        return decorated(string: string, suffix: suffix, symbol: symbol, signType: signType, signValue: value, tooSmall: tooSmall)
    }

    func formatFull(value: Decimal, decimalCount: Int, symbol: String? = nil, signType: SignType = .never) -> String? {
        let (transformedValue, digits) = transformedFull(value: value, maxDigits: decimalCount, minDigits: min(decimalCount, 4))

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: transformedValue as NSDecimalNumber)
        }

        guard let string else {
            return nil
        }

        return decorated(string: string, symbol: symbol, signType: signType, signValue: value)
    }

    func formatShort(coinValue: CoinValue, showCode: Bool = true, signType: SignType = .never) -> String? {
        formatShort(value: coinValue.value, decimalCount: coinValue.decimals, symbol: showCode ? coinValue.symbol : nil, signType: signType)
    }

    func formatFull(coinValue: CoinValue, showCode: Bool = true, signType: SignType = .never) -> String? {
        formatFull(value: coinValue.value, decimalCount: coinValue.decimals, symbol: showCode ? coinValue.symbol : nil, signType: signType)
    }

    func formatShort(currency: Currency, value: Decimal, signType: SignType = .never) -> String? {
        let (transformedValue, digits, suffix, tooSmall) = transformedShort(value: value)

        guard let string = formattedCurrency(value: transformedValue, digits: digits, code: currency.code, symbol: currency.symbol, suffix: suffix) else {
            return nil
        }

        return decorated(string: string, signType: signType, signValue: value, tooSmall: tooSmall)
    }

    func formatShort(currencyValue: CurrencyValue, signType: SignType = .never) -> String? {
        formatShort(currency: currencyValue.currency, value: currencyValue.value, signType: signType)
    }

    func formatFull(currency: Currency, value: Decimal, signType: SignType = .never) -> String? {
        let (transformedValue, digits) = transformedFull(value: value, maxDigits: 18)

        guard let string = formattedCurrency(value: transformedValue, digits: digits, code: currency.code, symbol: currency.symbol) else {
            return nil
        }

        return decorated(string: string, signType: signType, signValue: value)
    }

    func formatFull(currencyValue: CurrencyValue, signType: SignType = .never) -> String? {
        formatFull(currency: currencyValue.currency, value: currencyValue.value, signType: signType)
    }

    func format(percentValue: Decimal, signType: SignType = .always) -> String? {
        let (transformedValue, digits) = transformedFull(value: percentValue, maxDigits: 2)

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: transformedValue as NSDecimalNumber)
        }

        guard let string else {
            return nil
        }

        return decorated(string: string, signType: signType, signValue: percentValue) + "%"
    }
}

extension ValueFormatter {
    enum SignType {
        case never
        case auto
        case always
    }
}
