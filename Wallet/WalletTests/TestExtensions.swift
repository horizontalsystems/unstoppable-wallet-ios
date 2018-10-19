import Foundation
@testable import Bank

extension CoinValue: Equatable {
    public static func ==(lhs: CoinValue, rhs: CoinValue) -> Bool {
        return lhs.coin == rhs.coin && lhs.value == rhs.value
    }
}

extension Currency: Equatable {
    public static func ==(lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code == rhs.code && lhs.symbol == rhs.symbol
    }
}

extension CurrencyValue: Equatable {
    public static func ==(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        return lhs.currency == rhs.currency && lhs.value == rhs.value
    }
}
