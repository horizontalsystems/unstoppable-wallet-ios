import Foundation

class ValueFormatter {
    static let instance = ValueFormatter()

    static private let fractionDigits = 8

    enum FractionPolicy {
        case full
        case threshold(threshold: Decimal)
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

    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = ValueFormatter.fractionDigits
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let twoDigitFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let parseFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    var decimalSeparator: String {
        return amountFormatter.decimalSeparator
    }

    func format(coinValue: CoinValue, fractionPolicy: FractionPolicy = .full) -> String? {
        let absoluteValue = abs(coinValue.value)

        let formatter = coinFormatter
        formatter.roundingMode = .halfUp

        switch fractionPolicy {
        case .full:
            formatter.maximumFractionDigits = 8
        case let .threshold(threshold):
            formatter.maximumFractionDigits = absoluteValue > threshold ? 4 : 8
        }

        guard let formattedValue = formatter.string(from: absoluteValue as NSNumber) else {
            return nil
        }

        var result = "\(formattedValue) \(coinValue.coinCode)"

        if coinValue.value.isSignMinus {
            result = "- \(result)"
        }

        return result
    }

    func format(currencyValue: CurrencyValue, fractionPolicy: FractionPolicy = .full, smallValueThreshold: Decimal = 0.01, roundingMode: NumberFormatter.RoundingMode = .halfUp) -> String? {
        var absoluteValue = abs(currencyValue.value)

        let formatter = currencyFormatter
        formatter.roundingMode = roundingMode
        formatter.currencyCode = currencyValue.currency.code
        formatter.currencySymbol = currencyValue.currency.symbol

        switch fractionPolicy {
        case .full:
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        case let .threshold(threshold):
            formatter.maximumFractionDigits = absoluteValue > threshold ? 0 : 2
            formatter.minimumFractionDigits = 0
        }

        var showSmallSign = false

        if absoluteValue > 0 && absoluteValue < smallValueThreshold {
            absoluteValue = smallValueThreshold
            showSmallSign = true
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

    func format(amount: Decimal) -> String? {
        return amountFormatter.string(from: amount as NSNumber)
    }

    func format(twoDigitValue: Decimal) -> String? {
        return twoDigitFormatter.string(from: twoDigitValue as NSNumber)
    }

    func parseAnyDecimal(from string: String?) -> Decimal? {
        if let string = string {
            for localeIdentifier in Locale.availableIdentifiers {
                parseFormatter.locale = Locale(identifier: localeIdentifier)
                if parseFormatter.number(from: "0\(string)") == nil {
                    continue
                }

                let string = string.replacingOccurrences(of: parseFormatter.decimalSeparator, with: ".")
                if let decimal = Decimal(string: string) {
                    return decimal
                }
            }
        }
        return nil
    }

    func format(number: Int) -> String? {//translator for numpad
        return amountFormatter.string(from: number as NSNumber)
    }

    func round(value: Decimal, scale: Int, roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
        let handler = NSDecimalNumberHandler(roundingMode: roundingMode, scale: Int16(truncatingIfNeeded: scale), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: value).rounding(accordingToBehavior: handler).decimalValue
    }

}
