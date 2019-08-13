import Foundation

class ValueFormatter {
    static let instance = ValueFormatter()

    static private let fractionDigits = 8

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

    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = ValueFormatter.fractionDigits
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
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
        case let .threshold(high, _):
            formatter.maximumFractionDigits = absoluteValue > high ? 4 : 8
        }

        guard let formattedValue = formatter.string(from: absoluteValue as NSNumber) else {
            return nil
        }

        var result = "\(formattedValue) \(coinValue.coin.code)"

        if coinValue.value.isSignMinus {
            result = "- \(result)"
        }

        return result
    }

    func formatNew(coinValue: CoinValue) -> String? {
        coinFormatter.roundingMode = .halfUp
        coinFormatter.maximumFractionDigits = coinValue.coin.decimal

        guard let formattedValue = coinFormatter.string(from: coinValue.value as NSNumber) else {
            return nil
        }

        return "\(formattedValue) \(coinValue.coin.code)"
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
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        case let .threshold(high, low):
            formatter.maximumFractionDigits = absoluteValue > high ? 0 : 2
            formatter.maximumFractionDigits = !trimmable && absoluteValue < low ? 4 : formatter.maximumFractionDigits
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

    func formatNew(currencyValue: CurrencyValue) -> String? {
        currencyFormatter.roundingMode = .halfUp
        currencyFormatter.currencyCode = currencyValue.currency.code
        currencyFormatter.currencySymbol = currencyValue.currency.symbol
        currencyFormatter.maximumFractionDigits = currencyValue.currency.decimal
        currencyFormatter.minimumFractionDigits = 0

        return currencyFormatter.string(from: currencyValue.value as NSNumber)
    }

    func format(amount: Decimal) -> String? {
        return amountFormatter.string(from: amount as NSNumber)
    }

    func formatValue(coinValue: CoinValue) -> String? {
        decimalFormatter.maximumFractionDigits = coinValue.coin.decimal
        return decimalFormatter.string(from: coinValue.value as NSNumber)
    }

    func formatValue(currencyValue: CurrencyValue) -> String? {
        decimalFormatter.maximumFractionDigits = currencyValue.currency.decimal
        return decimalFormatter.string(from: currencyValue.value as NSNumber)
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
