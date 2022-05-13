import UIKit
import RxSwift
import CurrencyKit
import HsToolKit
import MarketKit

enum AmountInfo {
    case coinValue(coinValue: CoinValue)
    case currencyValue(currencyValue: CurrencyValue)

    var formattedString: String? {
        switch self {
        case .coinValue(let coinValue):
            return coinValue.formattedString
        case .currencyValue(let currencyValue):
            return ValueFormatter.instance.format(currencyValue: currencyValue)
        }
    }

    var formattedRawString: String? {
        switch self {
        case .coinValue(let coinValue):
            return coinValue.formattedRawString
        case .currencyValue(let currencyValue):
            return ValueFormatter.instance.format(currencyValue: currencyValue)
        }
    }

    var value: Decimal {
        switch self {
        case .currencyValue(let currencyValue): return currencyValue.value
        case .coinValue(let coinValue): return coinValue.value
        }
    }

    var decimal: Int {
        switch self {
        case .currencyValue(let currencyValue): return currencyValue.currency.decimal
        case .coinValue(let coinValue): return coinValue.decimals
        }
    }

}

struct AmountData {
    let primary: AmountInfo
    let secondary: AmountInfo?

    var formattedString: String {
        var parts = [String]()

        if let formatted = primary.formattedString {
            parts.append(formatted)
        }

        if let formatted = secondary?.formattedString {
            parts.append(formatted)
        }

        return parts.joined(separator: "  |  ")
    }

    var formattedRawString: String {
        var parts = [String]()

        if let formatted = primary.formattedRawString {
            parts.append(formatted)
        }

        if let formatted = secondary?.formattedRawString {
            parts.append(formatted)
        }

        return parts.joined(separator: "  |  ")
    }

}
