import Foundation

struct CurrencyValue {
    let currency: Currency
    let value: Decimal

    init(currency: Currency, value: Decimal) {
        self.currency = currency
        self.value = value
    }
}

extension CurrencyValue: Equatable {
    static func == (lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.currency == rhs.currency && lhs.value == rhs.value
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
