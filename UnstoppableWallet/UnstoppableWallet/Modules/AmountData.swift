import UIKit
import RxSwift
import CurrencyKit
import HsToolKit
import MarketKit

enum AmountInfo {
    case coinValue(coinValue: CoinValue)
    case currencyValue(currencyValue: CurrencyValue)

    var formattedFull: String? {
        switch self {
        case .coinValue(let coinValue):
            return coinValue.formattedFull
        case .currencyValue(let currencyValue):
            return currencyValue.formattedFull
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
