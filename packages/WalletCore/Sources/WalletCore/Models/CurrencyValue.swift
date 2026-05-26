import Foundation

public struct CurrencyValue: Hashable {
    public let currency: Currency
    public let value: Decimal

    public init(currency: Currency, value: Decimal) {
        self.currency = currency
        self.value = value
    }
}

public extension CurrencyValue {
    var formattedFull: String? {
        ValueFormatter.instance.formatFull(currencyValue: self)
    }

    var formattedShort: String? {
        ValueFormatter.instance.formatShort(currencyValue: self)
    }
}
