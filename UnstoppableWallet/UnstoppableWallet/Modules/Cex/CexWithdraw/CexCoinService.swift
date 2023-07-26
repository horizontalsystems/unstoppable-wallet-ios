import Foundation
import CurrencyKit
import BigInt
import MarketKit
import HsExtensions

class CexCoinService {
    let cexAsset: CexAsset
    private let currencyKit: CurrencyKit.Kit
    private let marketKit: MarketKit.Kit

    init(cexAsset: CexAsset, currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit) {
        self.cexAsset = cexAsset
        self.currencyKit = currencyKit
        self.marketKit = marketKit
    }

}

extension CexCoinService: ICoinService {

    var rate: CurrencyValue? {
        guard let coin = cexAsset.coin else {
            return nil
        }

        let baseCurrency = currencyKit.baseCurrency

        return marketKit.coinPrice(coinUid: coin.uid, currencyCode: baseCurrency.code).map { coinPrice in
            CurrencyValue(currency: baseCurrency, value: coinPrice.value)
        }
    }

    func coinValue(value: BigUInt) -> CoinValue {
        let decimalValue = Decimal(bigUInt: value, decimals: CexAsset.decimals) ?? 0
        return coinValue(value: decimalValue)
    }

    func coinValue(value: Decimal) -> CoinValue {
        CoinValue(kind: .cexAsset(cexAsset: cexAsset), value: value)
    }

    // Example: Dollar, Bitcoin, Ether, etc
    func monetaryValue(value: BigUInt) -> Decimal {
        coinValue(value: value).value
    }

    // Example: Cent, Satoshi, GWei, etc
    func fractionalMonetaryValue(value: Decimal) -> BigUInt {
        BigUInt(value.hs.roundedString(decimal: CexAsset.decimals)) ?? 0
    }

    func amountData(value: Decimal, sign: FloatingPointSign) -> AmountData {
        AmountData(
            coinValue: coinValue(value: Decimal(sign: sign, exponent: value.exponent, significand: value.significand)),
            currencyValue: rate.map {
                CurrencyValue(currency: $0.currency, value: $0.value * value)
            }
        )
    }

    func amountData(value: BigUInt, sign: FloatingPointSign = .plus) -> AmountData {
        amountData(value: Decimal(bigUInt: value, decimals: CexAsset.decimals) ?? 0, sign: sign)
    }

}
