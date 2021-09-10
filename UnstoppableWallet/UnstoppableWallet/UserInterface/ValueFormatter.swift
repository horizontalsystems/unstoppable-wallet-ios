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

    func format(coinValue: CoinValue, showCode: Bool = true, fractionPolicy: FractionPolicy = .full) -> String? {
        format(value: coinValue.value, decimalCount: coinValue.coin.decimal, symbol: showCode ? coinValue.coin.code : nil, fractionPolicy: fractionPolicy)
    }

    func format(coinValueNew: CoinValueNew, showCode: Bool = true, fractionPolicy: FractionPolicy = .full) -> String? {
        format(value: coinValueNew.value, decimalCount: coinValueNew.decimal, symbol: showCode ? coinValueNew.coin.code : nil, fractionPolicy: fractionPolicy)
    }

    func format(transactionValue: TransactionValue, showCode: Bool = true, fractionPolicy: FractionPolicy = .full) -> String? {
        switch transactionValue {
        case .coinValue(let platformCoin, let value):
            return format(value: value, decimalCount: platformCoin.decimal, symbol: showCode ? platformCoin.coin.code : nil, fractionPolicy: fractionPolicy)
        case .rawValue:
            return nil
        }
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
