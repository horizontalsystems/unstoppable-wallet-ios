import BigInt
import Foundation
import HsExtensions
import MarketKit

protocol ICoinService {
    var rate: CurrencyValue? { get }
    func appValue(value: BigUInt) -> AppValue
    func appValue(value: Decimal) -> AppValue
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

    func appValue(value: BigUInt) -> AppValue {
        let decimalValue = Decimal(bigUInt: value, decimals: token.decimals) ?? 0
        return appValue(value: decimalValue)
    }

    func appValue(value: Decimal) -> AppValue {
        AppValue(token: token, value: value)
    }

    // Example: Dollar, Bitcoin, Ether, etc
    func monetaryValue(value: BigUInt) -> Decimal {
        appValue(value: value).value
    }

    // Example: Cent, Satoshi, GWei, etc
    func fractionalMonetaryValue(value: Decimal) -> BigUInt {
        token.fractionalMonetaryValue(value: value)
    }

    func amountData(value: Decimal, sign: FloatingPointSign) -> AmountData {
        AmountData(kind: .token(token: token), value: value, sign: sign, currency: rate?.currency, rate: rate?.value)
    }

    func amountData(value: BigUInt, sign: FloatingPointSign = .plus) -> AmountData {
        amountData(value: Decimal(bigUInt: value, decimals: token.decimals) ?? 0, sign: sign)
    }
}
