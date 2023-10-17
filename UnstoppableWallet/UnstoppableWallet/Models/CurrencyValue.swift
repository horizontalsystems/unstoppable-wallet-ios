import Foundation

public struct CurrencyValue {
    public let currency: Currency
    public let value: Decimal

    public init(currency: Currency, value: Decimal) {
        self.currency = currency
        self.value = value
    }
}

extension CurrencyValue: Equatable {
    public static func == (lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.currency == rhs.currency && lhs.value == rhs.value
    }
}

extension CurrencyValue {
    var formattedFull: String? {
        ValueFormatter.instance.formatFull(currencyValue: self)
    }
}
