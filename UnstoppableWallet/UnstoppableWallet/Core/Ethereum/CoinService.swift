import Foundation
import CurrencyKit
import BigInt
import MarketKit
import HsExtensions

class CoinService {
    let token: Token
    private let currencyKit: CurrencyKit.Kit
    private let marketKit: MarketKit.Kit

    init(token: Token, currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit) {
        self.token = token
        self.currencyKit = currencyKit
        self.marketKit = marketKit
    }

}

extension CoinService {

    var rate: CurrencyValue? {
        let baseCurrency = currencyKit.baseCurrency

        return marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: baseCurrency.code).map { coinPrice in
            CurrencyValue(currency: baseCurrency, value: coinPrice.value)
        }
    }

    func coinValue(value: BigUInt) -> CoinValue {
        let decimalValue = Decimal(bigUInt: value, decimals: token.decimals) ?? 0
        return CoinValue(kind: .token(token: token), value: decimalValue)
    }

    // Example: Dollar, Bitcoin, Ether, etc
    func monetaryValue(value: BigUInt) -> Decimal {
        coinValue(value: value).value
    }

    // Example: Cent, Satoshi, GWei, etc
    func fractionalMonetaryValue(value: Decimal) -> BigUInt {
        BigUInt(value.hs.roundedString(decimal: token.decimals)) ?? 0
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
