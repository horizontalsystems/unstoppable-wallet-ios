import Foundation

struct CurrencyValue {
    let currency: Currency
    let value: Decimal
}

extension CurrencyValue: Equatable {
    public static func ==(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.currency == rhs.currency && lhs.value == rhs.value
    }
}
