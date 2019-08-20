import Foundation

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

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

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
        coinFormatter.maximumFractionDigits = min(coinValue.coin.decimal, 8)

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

    func formatValue(coinValue: CoinValue) -> String? {
        decimalFormatter.maximumFractionDigits = min(coinValue.coin.decimal, 8)
        return decimalFormatter.string(from: coinValue.value as NSNumber)
    }

    func formatValue(currencyValue: CurrencyValue) -> String? {
        decimalFormatter.maximumFractionDigits = currencyValue.currency.decimal
        return decimalFormatter.string(from: currencyValue.value as NSNumber)
    }

}
