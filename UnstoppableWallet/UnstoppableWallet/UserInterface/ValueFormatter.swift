import Foundation
import CurrencyKit

class ValueFormatter {
    static let instance = ValueFormatter()

    enum FractionPolicy {
        case full
        case threshold(high: Decimal, low: Decimal)
    }

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
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
        case pow(10, basePow)..<pow(10, basePow + 1): digits = 2
        case pow(10, basePow + 1)..<pow(10, basePow + 2): digits = 1
        default: digits = 0
        }

        return (digits, value / pow(10, basePow))
    }

}

extension ValueFormatter {

    func format(coinValue: CoinValue, showCode: Bool = true, fractionPolicy: FractionPolicy = .full) -> String? {
        format(value: coinValue.value, decimalCount: coinValue.decimals, symbol: showCode ? coinValue.coin.code : nil, fractionPolicy: fractionPolicy)
    }

    func format(transactionValue: TransactionValue, showCode: Bool = true, fractionPolicy: FractionPolicy = .full) -> String? {
        switch transactionValue {
        case let .coinValue(platformCoin, value):
            return format(value: value, decimalCount: platformCoin.decimals, symbol: showCode ? platformCoin.coin.code : nil, fractionPolicy: fractionPolicy)
        case let .tokenValue(_, tokenCode, tokenDecimals, value):
            return format(value: value, decimalCount: tokenDecimals, symbol: showCode ? tokenCode : nil, fractionPolicy: fractionPolicy)
        case .rawValue:
            return nil
        }
    }

    func formatNew(transactionValue: TransactionValue) -> String? {
        switch transactionValue {
        case let .coinValue(platformCoin, value):
            return formatNew(value: value, decimalCount: platformCoin.decimals, symbol: platformCoin.coin.code)
        case let .tokenValue(_, tokenCode, tokenDecimals, value):
            return formatNew(value: value, decimalCount: tokenDecimals, symbol: tokenCode)
        case .rawValue:
            return nil
        }
    }
    
    func formatNew(value: Decimal, decimalCount: Int, symbol: String?) -> String? {
        var value = abs(value)
        var postfix: String?
        let digits: Int

        switch value {
        case 0:
            digits = 0

        case 0..<0.0000_0001:
            digits = 8
            value = 0.0000_0001

        case 0.0000_0001..<0.0001:
            digits = min(decimalCount, 8)

        case 0.0001..<1:
            digits = 4

        case 1..<10:
            digits = 2

        case 10..<100:
            digits = 1

        case 100..<10_000:
            digits = 0

        case 10_000..<pow(10, 6):
            (digits, value) = digitsAndValue(value: value, basePow: 3)
            postfix = "number.thousand"

        case pow(10, 6)..<pow(10, 9):
            (digits, value) = digitsAndValue(value: value, basePow: 6)
            postfix = "number.million"

        case pow(10, 9)..<pow(10, 12):
            (digits, value) = digitsAndValue(value: value, basePow: 9)
            postfix = "number.billion"

        default:
            (digits, value) = digitsAndValue(value: value, basePow: 12)
            postfix = "number.trillion"
        }

        let formatter = coinFormatter
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = digits

        guard let formattedValue = formatter.string(from: value as NSNumber) else {
            return nil
        }

        let valueWithPostfix = postfix.map { $0.localized(formattedValue) } ?? formattedValue
        return "\(valueWithPostfix)\(symbol.map { " \($0)" } ?? "")"
    }

    func format(value: Decimal, decimalCount: Int, symbol: String?, fractionPolicy: FractionPolicy = .full) -> String? {
        var absoluteValue = abs(value)
        var rounded = false

        let formatter = coinFormatter
        formatter.roundingMode = .halfUp

        switch fractionPolicy {
        case .full:
            formatter.maximumFractionDigits = min(decimalCount, 8)
        case let .threshold(high, _):
            formatter.maximumFractionDigits = absoluteValue > high ? 4 : 8
        }

        if absoluteValue > 0 && absoluteValue < 0.00000001 {
            absoluteValue = 0.00000001
            rounded = true
        }

        guard let formattedValue = formatter.string(from: absoluteValue as NSNumber) else {
            return nil
        }

        var result = symbol.map { "\(formattedValue) \($0)" } ?? formattedValue

        if rounded {
            result = "< \(result)"
        }

        if value.isSignMinus {
            result = "- \(result)"
        }

        return result
    }

    func format(currencyValue: CurrencyValue, fractionPolicy: FractionPolicy = .full, trimmable: Bool = true, roundingMode: NumberFormatter.RoundingMode = .halfUp) -> String? {
        var absoluteValue = abs(currencyValue.value)

        let formatter = currencyFormatter
        formatter.roundingMode = roundingMode
        formatter.currencyCode = currencyValue.currency.code
        formatter.currencySymbol = currencyValue.currency.symbol

        var showSmallSign = false

        switch fractionPolicy {
        case .full:
            formatter.maximumFractionDigits = currencyValue.currency.decimal
            formatter.minimumFractionDigits = currencyValue.currency.decimal
        case let .threshold(high, low):
            if trimmable {
                formatter.maximumFractionDigits = absoluteValue > high ? 0 : 2
            } else {
                formatter.maximumFractionDigits = absoluteValue.significantDecimalCount(threshold: high, maxDecimals: 8)
            }
            formatter.minimumFractionDigits = 0

            if absoluteValue > 0 && absoluteValue < low && trimmable {
                absoluteValue = low
                showSmallSign = true
            }
        }

        guard var result = formatter.string(from: absoluteValue as NSNumber) else {
            return nil
        }

        if showSmallSign {
            result = "< \(result)"
        }

        if currencyValue.value.isSignMinus {
            result = "- \(result)"
        }

        return result
    }

    func format(percentValue: Decimal, signed: Bool = true) -> String? {
        let plusSign = (percentValue >= 0 && signed) ? "+" : ""

        let formattedDiff = percentFormatter.string(from: percentValue as NSNumber)
        return formattedDiff.map { plusSign + $0 + "%" }
    }

}
