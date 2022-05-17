import Foundation
import CurrencyKit

class ValueFormatter {
    static let instance = ValueFormatter()

    private let rawFormatterQueue = DispatchQueue(label: "io.horizontalsystems.unstoppable.value-formatter.raw-formatter", qos: .utility)
    private let currencyFormatterQueue = DispatchQueue(label: "io.horizontalsystems.unstoppable.value-formatter.currency-formatter", qos: .utility)

    private let rawFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfEven
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private func digitsAndValue(value: Decimal, basePow: Int) -> (Int, Decimal) {
        let digits: Int

        switch value {
        case pow(10, basePow)..<(2 * pow(10, basePow + 1)): digits = 2
        case (2 * pow(10, basePow + 1))..<(2 * pow(10, basePow + 2)): digits = 1
        default: digits = 0
        }

        return (digits, value / pow(10, basePow))
    }

    private func fractionZeroCount(value: Decimal, maxCount: Int) -> Int {
        guard value > 0 && value < 1 else {
            return 0
        }

        for count in 0..<maxCount {
            if value * pow(10, count + 1) >= 1 {
                return count
            }
        }

        return maxCount
    }

    private func transformedShort(value: Decimal, maxDecimalCount: Int) -> (value: Decimal, digits: Int, suffix: String?, tooSmall: Bool) {
        var value = abs(value)
        var suffix: String?
        let digits: Int
        var tooSmall = false

        switch value {
        case 0:
            digits = 0

        case 0..<0.0000_0001:
            digits = 8
            value = 0.0000_0001
            tooSmall = true

        case 0.0000_0001..<1:
            let zeroCount = fractionZeroCount(value: value, maxCount: 8)
            digits = min(maxDecimalCount, zeroCount + 4, 8)

        case 1..<1.01:
            digits = 4

        case 1.01..<1.1:
            digits = 3

        case 1.1..<20:
            digits = 2

        case 20..<200:
            digits = 1

        case 200..<20_000:
            digits = 0

        case 20_000..<pow(10, 6):
            (digits, value) = digitsAndValue(value: value, basePow: 3)
            suffix = "number.thousand"

        case pow(10, 6)..<pow(10, 9):
            (digits, value) = digitsAndValue(value: value, basePow: 6)
            suffix = "number.million"

        case pow(10, 9)..<pow(10, 12):
            (digits, value) = digitsAndValue(value: value, basePow: 9)
            suffix = "number.billion"

        default:
            (digits, value) = digitsAndValue(value: value, basePow: 12)
            suffix = "number.trillion"
        }

        return (value: value, digits: digits, suffix: suffix, tooSmall: tooSmall)
    }

    private func transformedFull(value: Decimal, maxDecimalCount: Int, minDigits: Int) -> (value: Decimal, digits: Int) {
        var value = abs(value)
        let digits: Int

        switch value {
        case 0:
            digits = 0

        case 0..<1:
            let zeroCount = fractionZeroCount(value: value, maxCount: maxDecimalCount - 1)
            digits = min(maxDecimalCount, zeroCount + 4)

        case 1..<1.01:
            digits = 4

        case 1.01..<1.1:
            digits = 3

        case 1.1..<20:
            digits = 2

        case 20..<200:
            digits = 1

        default:
            digits = 0
        }

        return (value: value, digits: max(digits, minDigits))
    }

    private func decorated(string: String, suffix: String? = nil, symbol: String? = nil, signValue: Decimal? = nil, tooSmall: Bool = false) -> String {
        var string = string

        if let suffix = suffix {
            string = suffix.localized(string)
        }

        if let symbol = symbol {
            string = "\(string) \(symbol)"
        }

        if let signValue = signValue {
            let sign = signValue.isSignMinus ? "-" : "+"
            string = "\(sign)\(string)"
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

        guard let pattern = pattern else {
            return nil
        }

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: value as NSDecimalNumber)
        }

        guard let string = string else {
            return nil
        }

        return pattern.replacingOccurrences(of: "1", with: decorated(string: string, suffix: suffix))
    }

}

extension ValueFormatter {

    func formatShort(value: Decimal) -> String? {
        let (transformedValue, digits, suffix, tooSmall) = transformedShort(value: value, maxDecimalCount: 8)

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: transformedValue as NSDecimalNumber)
        }

        guard let string = string else {
            return nil
        }

        return decorated(string: string, suffix: suffix, tooSmall: tooSmall)
    }

    func formatShort(value: Decimal, decimalCount: Int, symbol: String? = nil, showSign: Bool = false) -> String? {
        let (transformedValue, digits, suffix, tooSmall) = transformedShort(value: value, maxDecimalCount: decimalCount)

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: transformedValue as NSDecimalNumber)
        }

        guard let string = string else {
            return nil
        }

        return decorated(string: string, suffix: suffix, symbol: symbol, signValue: showSign ? value : nil, tooSmall: tooSmall)
    }

    func formatFull(value: Decimal, decimalCount: Int, symbol: String? = nil, showSign: Bool = false) -> String? {
        let (transformedValue, digits) = transformedFull(value: value, maxDecimalCount: decimalCount, minDigits: min(decimalCount, 4))

        let string: String? = rawFormatterQueue.sync {
            rawFormatter.maximumFractionDigits = digits
            return rawFormatter.string(from: transformedValue as NSDecimalNumber)
        }

        guard let string = string else {
            return nil
        }

        return decorated(string: string, symbol: symbol, signValue: showSign ? value : nil)
    }

    func formatShort(coinValue: CoinValue, showCode: Bool = true, showSign: Bool = false) -> String? {
        formatShort(value: coinValue.value, decimalCount: coinValue.decimals, symbol: showCode ? coinValue.coin.code : nil, showSign: showSign)
    }

    func formatFull(coinValue: CoinValue, showCode: Bool = true, showSign: Bool = false) -> String? {
        formatFull(value: coinValue.value, decimalCount: coinValue.decimals, symbol: showCode ? coinValue.coin.code : nil, showSign: showSign)
    }

    func formatShort(currency: Currency, value: Decimal, showSign: Bool = false) -> String? {
        let (transformedValue, digits, suffix, tooSmall) = transformedShort(value: value, maxDecimalCount: 8)

        guard let string = formattedCurrency(value: transformedValue, digits: digits, code: currency.code, symbol: currency.symbol, suffix: suffix) else {
            return nil
        }

        return decorated(string: string, signValue: showSign ? value : nil, tooSmall: tooSmall)
    }

    func formatShort(currencyValue: CurrencyValue, showSign: Bool = false) -> String? {
        formatShort(currency: currencyValue.currency, value: currencyValue.value, showSign: showSign)
    }

    func formatFull(currency: Currency, value: Decimal, showSign: Bool = false) -> String? {
        let (transformedValue, digits) = transformedFull(value: value, maxDecimalCount: 8, minDigits: 0)

        guard let string = formattedCurrency(value: transformedValue, digits: digits, code: currency.code, symbol: currency.symbol) else {
            return nil
        }

        return decorated(string: string, signValue: showSign ? value : nil)
    }

    func formatFull(currencyValue: CurrencyValue, showSign: Bool = false) -> String? {
        formatFull(currency: currencyValue.currency, value: currencyValue.value, showSign: showSign)
    }

    func format(percentValue: Decimal, showSign: Bool = true) -> String? {
        guard let string = percentFormatter.string(from: abs(percentValue) as NSNumber) else {
            return nil
        }

        return decorated(string: string, signValue: showSign ? percentValue : nil) + "%"
    }

}
