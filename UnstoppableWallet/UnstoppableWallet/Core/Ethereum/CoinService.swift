import CurrencyKit
import BigInt
import MarketKit

class CoinService {
    let platformCoin: PlatformCoin
    private let currencyKit: CurrencyKit.Kit
    private let marketKit: MarketKit.Kit

    init(platformCoin: PlatformCoin, currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit) {
        self.platformCoin = platformCoin
        self.currencyKit = currencyKit
        self.marketKit = marketKit
    }

}

extension CoinService {

    var rate: CurrencyValue? {
        let baseCurrency = currencyKit.baseCurrency

        return marketKit.coinPrice(coinUid: platformCoin.coin.uid, currencyCode: baseCurrency.code).map { coinPrice in
            CurrencyValue(currency: baseCurrency, value: coinPrice.value)
        }
    }

    func coinValue(value: BigUInt) -> CoinValue {
        let decimalValue = Decimal(bigUInt: value, decimals: platformCoin.decimals) ?? 0
        return CoinValue(kind: .platformCoin(platformCoin: platformCoin), value: decimalValue)
    }

    // Example: Dollar, Bitcoin, Ether, etc
    func monetaryValue(value: BigUInt) -> Decimal {
        coinValue(value: value).value
    }

    // Example: Cent, Satoshi, GWei, etc
    func fractionalMonetaryValue(value: Decimal) -> BigUInt {
        BigUInt(value.roundedString(decimal: platformCoin.decimals)) ?? 0
    }

    func amountData(value: Decimal) -> AmountData {
        let primaryInfo: AmountInfo
        var secondaryInfo: AmountInfo?

        let coinValue = CoinValue(kind: .platformCoin(platformCoin: platformCoin), value: value)

        if let rate = rate {
            primaryInfo = .coinValue(coinValue: coinValue)
            secondaryInfo = .currencyValue(currencyValue: CurrencyValue(currency: rate.currency, value: rate.value * value))
        } else {
            primaryInfo = .coinValue(coinValue: coinValue)
        }

        return AmountData(primary: primaryInfo, secondary: secondaryInfo)
    }

    func amountData(value: BigUInt) -> AmountData {
        amountData(value: Decimal(bigUInt: value, decimals: platformCoin.decimals) ?? 0)
    }

}
