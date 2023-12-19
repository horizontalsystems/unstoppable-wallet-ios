import HsToolKit
import MarketKit
import RxSwift
import UIKit

enum AmountInfo {
    case coinValue(coinValue: CoinValue)
    case currencyValue(currencyValue: CurrencyValue)

    var formattedFull: String? {
        switch self {
        case let .coinValue(coinValue):
            return coinValue.formattedFull
        case let .currencyValue(currencyValue):
            return currencyValue.formattedFull
        }
    }

    var value: Decimal {
        switch self {
        case let .currencyValue(currencyValue): return currencyValue.value
        case let .coinValue(coinValue): return coinValue.value
        }
    }

    var decimal: Int {
        switch self {
        case let .currencyValue(currencyValue): return currencyValue.currency.decimal
        case let .coinValue(coinValue): return coinValue.decimals
        }
    }
}

struct AmountData {
    let coinValue: CoinValue
    let currencyValue: CurrencyValue?

    var formattedFull: String {
        var parts = [String]()

        if let formatted = coinValue.formattedFull {
            parts.append(formatted)
        }

        if let formatted = currencyValue?.formattedFull {
            parts.append(formatted)
        }

        return parts.joined(separator: "  |  ")
    }
}
