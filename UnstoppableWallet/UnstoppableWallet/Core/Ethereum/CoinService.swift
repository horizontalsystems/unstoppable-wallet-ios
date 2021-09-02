import CurrencyKit
import BigInt
import MarketKit

class CoinService {
    let platformCoin: PlatformCoin
    private let currencyKit: CurrencyKit.Kit
    private let rateManager: RateManagerNew

    init(platformCoin: PlatformCoin, currencyKit: CurrencyKit.Kit, rateManager: RateManagerNew) {
        self.platformCoin = platformCoin
        self.currencyKit = currencyKit
        self.rateManager = rateManager
    }

}

extension CoinService {

    var rate: CurrencyValue? {
        let baseCurrency = currencyKit.baseCurrency

        return rateManager.latestRate(coinType: platformCoin.coinType, currencyCode: baseCurrency.code).map { latestRate in
            CurrencyValue(currency: baseCurrency, value: latestRate.rate)
        }
    }

    func coinValue(value: BigUInt) -> CoinValueNew {
        let decimalValue = Decimal(bigUInt: value, decimal: platformCoin.decimal) ?? 0
        return CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: decimalValue)
    }

    // Example: Dollar, Bitcoin, Ether, etc
    func monetaryValue(value: BigUInt) -> Decimal {
        coinValue(value: value).value
    }

    // Example: Cent, Satoshi, GWei, etc
    func fractionalMonetaryValue(value: Decimal) -> BigUInt {
        BigUInt(value.roundedString(decimal: platformCoin.decimal)) ?? 0
    }

    func amountData(value: Decimal) -> AmountData {
        let primaryInfo: AmountInfo
        var secondaryInfo: AmountInfo?

        let coinValue = CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: value)

        if let rate = rate {
            primaryInfo = .coinValue(coinValue: coinValue)
            secondaryInfo = .currencyValue(currencyValue: CurrencyValue(currency: rate.currency, value: rate.value * value))
        } else {
            primaryInfo = .coinValue(coinValue: coinValue)
        }

        return AmountData(primary: primaryInfo, secondary: secondaryInfo)
    }

    func amountData(value: BigUInt) -> AmountData {
        amountData(value: Decimal(bigUInt: value, decimal: platformCoin.decimal) ?? 0)
    }

}
