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
            return ValueFormatter.instance.formatFull(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            return ValueFormatter.instance.formatFull(currencyValue: currencyValue)
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

        if let formatted = ValueFormatter.instance.formatFull(coinValue: coinValue) {
            parts.append(formatted)
        }

        if let currencyValue = currencyValue, let formatted = ValueFormatter.instance.formatFull(currencyValue: currencyValue) {
            parts.append(formatted)
        }

        return parts.joined(separator: "  |  ")
    }

}
