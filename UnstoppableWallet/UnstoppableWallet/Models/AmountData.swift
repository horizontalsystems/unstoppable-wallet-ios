import HsToolKit
import MarketKit
import RxSwift
import UIKit

enum AmountInfo {
    case appValue(appValue: AppValue)
    case currencyValue(currencyValue: CurrencyValue)

    var formattedFull: String? {
        switch self {
        case let .appValue(appValue):
            return appValue.formattedFull()
        case let .currencyValue(currencyValue):
            return currencyValue.formattedFull
        }
    }

    var value: Decimal {
        switch self {
        case let .currencyValue(currencyValue): return currencyValue.value
        case let .appValue(appValue): return appValue.value
        }
    }

    var decimal: Int {
        switch self {
        case let .currencyValue(currencyValue): return currencyValue.currency.decimal
        case let .appValue(appValue): return appValue.decimals ?? 0
        }
    }
}

struct AmountData {
    let appValue: AppValue
    let currencyValue: CurrencyValue?

    init(kind: AppValue.Kind, value: Decimal, sign: FloatingPointSign = .plus, currency: Currency?, rate: Decimal?) {
        appValue = AppValue(kind: kind, value: Decimal(sign: sign, exponent: value.exponent, significand: value.significand))
        currencyValue = appValue.currencyValue(currency: currency, rate: rate)
    }

    init(appValue: AppValue, rate: CurrencyValue?) {
        self.appValue = appValue
        currencyValue = appValue.currencyValue(currency: rate?.currency, rate: rate?.value)
    }

    var formattedFull: String {
        var parts = [String]()

        if let formatted = appValue.formattedFull() {
            parts.append(formatted)
        }

        if let formatted = currencyValue?.formattedFull {
            parts.append(formatted)
        }

        return parts.joined(separator: "  |  ")
    }

    var formattedShort: String {
        var result = ""

        if let formatted = appValue.formattedShort() {
            result += formatted
        }

        if let currencyValue, let formatted = ValueFormatter.instance.formatShort(currencyValue: currencyValue) {
            result += " (≈ \(formatted))"
        }

        return result
    }
}
