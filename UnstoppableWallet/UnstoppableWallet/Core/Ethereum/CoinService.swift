import BigInt
import Foundation
import HsExtensions
import MarketKit

protocol ICoinService {
    var rate: CurrencyValue? { get }
    func coinValue(value: BigUInt) -> CoinValue
    func coinValue(value: Decimal) -> CoinValue
    func monetaryValue(value: BigUInt) -> Decimal
    func fractionalMonetaryValue(value: Decimal) -> BigUInt
    func amountData(value: Decimal, sign: FloatingPointSign) -> AmountData
    func amountData(value: BigUInt, sign: FloatingPointSign) -> AmountData
}

class CoinService {
    let token: Token
    private let currencyManager: CurrencyManager
    private let marketKit: MarketKit.Kit

    init(token: Token, currencyManager: CurrencyManager, marketKit: MarketKit.Kit) {
        self.token = token
        self.currencyManager = currencyManager
        self.marketKit = marketKit
    }
}

extension CoinService: ICoinService {
    var rate: CurrencyValue? {
        let baseCurrency = currencyManager.baseCurrency

        return marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: baseCurrency.code).map { coinPrice in
            CurrencyValue(currency: baseCurrency, value: coinPrice.value)
        }
    }

    func coinValue(value: BigUInt) -> CoinValue {
        let decimalValue = Decimal(bigUInt: value, decimals: token.decimals) ?? 0
        return coinValue(value: decimalValue)
    }

    func coinValue(value: Decimal) -> CoinValue {
        CoinValue(kind: .token(token: token), value: value)
    }

    // Example: Dollar, Bitcoin, Ether, etc
    func monetaryValue(value: BigUInt) -> Decimal {
        coinValue(value: value).value
    }

    // Example: Cent, Satoshi, GWei, etc
    func fractionalMonetaryValue(value: Decimal) -> BigUInt {
        token.fractionalMonetaryValue(value: value)
    }

    func amountData(value: Decimal, sign: FloatingPointSign) -> AmountData {
        AmountData(
            coinValue: CoinValue(kind: .token(token: token), value: Decimal(sign: sign, exponent: value.exponent, significand: value.significand)),
            currencyValue: rate.map {
                CurrencyValue(currency: $0.currency, value: $0.value * value)
            }
        )
    }

    func amountData(value: BigUInt, sign: FloatingPointSign = .plus) -> AmountData {
        amountData(value: Decimal(bigUInt: value, decimals: token.decimals) ?? 0, sign: sign)
    }
}
