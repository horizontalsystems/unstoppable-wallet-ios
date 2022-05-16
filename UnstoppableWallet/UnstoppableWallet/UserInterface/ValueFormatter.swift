import Foundation
import CurrencyKit

class ValueFormatter {
    static let instance = ValueFormatter()

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

        case 10_000..<pow(10, 6):
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

    private func formattedCurrency(value: Decimal, digits: Int, code: String, symbol: String, suffix: String?) -> String? {
        let currencyFormatter = currencyFormatter
        currencyFormatter.currencyCode = code
        currencyFormatter.currencySymbol = symbol
        currencyFormatter.internationalCurrencySymbol = symbol

        guard let pattern = currencyFormatter.string(from: 1) else {
            return nil
        }

        let formatter = rawFormatter
        formatter.maximumFractionDigits = digits

        guard var result = formatter.string(from: value as NSNumber) else {
            return nil
        }

        if let suffix = suffix {
            result = suffix.localized(result)
        }

        return pattern.replacingOccurrences(of: "1", with: result)
    }

}

extension ValueFormatter {

    func formatShort(value: Decimal) -> String? {
        let (value, digits, suffix, tooSmall) = transformedShort(value: value, maxDecimalCount: 8)

        let formatter = rawFormatter
        formatter.maximumFractionDigits = digits

        guard var result = formatter.string(from: value as NSNumber) else {
            return nil
        }

        if let suffix = suffix {
            result = suffix.localized(result)
        }

        if tooSmall {
            result = "< \(result)"
        }

        return result
    }

    func formatShort(value: Decimal, decimalCount: Int, symbol: String?) -> String? {
        let (value, digits, postfix, tooSmall) = transformedShort(value: value, maxDecimalCount: decimalCount)

        let formatter = rawFormatter
        formatter.maximumFractionDigits = digits

        guard var result = formatter.string(from: value as NSNumber) else {
            return nil
        }

        if let postfix = postfix {
            result = postfix.localized(result)
        }

        if let symbol = symbol {
            result = "\(result) \(symbol)"
        }

        if tooSmall {
            result = "< \(result)"
        }

        return result
    }

    func formatFull(value: Decimal, decimalCount: Int, symbol: String?) -> String? {
        let (value, digits) = transformedFull(value: value, maxDecimalCount: decimalCount, minDigits: min(decimalCount, 4))

        let formatter = rawFormatter
        formatter.maximumFractionDigits = digits

        guard var result = formatter.string(from: value as NSNumber) else {
            return nil
        }

        if let symbol = symbol {
            result = "\(result) \(symbol)"
        }

        return result
    }

    func formatShort(coinValue: CoinValue, showCode: Bool = true) -> String? {
        formatShort(value: coinValue.value, decimalCount: coinValue.decimals, symbol: showCode ? coinValue.coin.code : nil)
    }

    func formatFull(coinValue: CoinValue, showCode: Bool = true) -> String? {
        formatFull(value: coinValue.value, decimalCount: coinValue.decimals, symbol: showCode ? coinValue.coin.code : nil)
    }

    func formatShort(currency: Currency, value: Decimal) -> String? {
        let (value, digits, suffix, tooSmall) = transformedShort(value: value, maxDecimalCount: 8)

        var result = formattedCurrency(
                value: value,
                digits: digits,
                code: currency.code,
                symbol: currency.symbol,
                suffix: suffix
        )

        if tooSmall {
            result = "< \(result)"
        }

        return result
    }

    func formatShort(currencyValue: CurrencyValue) -> String? {
        formatShort(currency: currencyValue.currency, value: currencyValue.value)
    }

    func formatFull(currency: Currency, value: Decimal) -> String? {
        let (value, digits) = transformedFull(value: value, maxDecimalCount: 8, minDigits: 0)

        return formattedCurrency(
                value: value,
                digits: digits,
                code: currency.code,
                symbol: currency.symbol,
                suffix: nil
        )
    }

    func formatFull(currencyValue: CurrencyValue) -> String? {
        formatFull(currency: currencyValue.currency, value: currencyValue.value)
    }

    func format(percentValue: Decimal, signed: Bool = true) -> String? {
        let plusSign = (percentValue >= 0 && signed) ? "+" : ""

        let formattedDiff = percentFormatter.string(from: percentValue as NSNumber)
        return formattedDiff.map { plusSign + $0 + "%" }
    }

}
