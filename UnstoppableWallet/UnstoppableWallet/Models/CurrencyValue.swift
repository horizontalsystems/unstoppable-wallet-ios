import Foundation

struct CurrencyValue: Hashable {
    let currency: Currency
    let value: Decimal

    init(currency: Currency, value: Decimal) {
        self.currency = currency
        self.value = value
    }
}

extension CurrencyValue {
    var formattedFull: String? {
        ValueFormatter.instance.formatFull(currencyValue: self)
    }

    var formattedShort: String? {
        ValueFormatter.instance.formatShort(currencyValue: self)
    }
}
