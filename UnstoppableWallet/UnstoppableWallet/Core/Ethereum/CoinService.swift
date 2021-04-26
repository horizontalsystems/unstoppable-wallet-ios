import CurrencyKit
import BigInt
import CoinKit

class CoinService {
    let coin: Coin
    private let currencyKit: CurrencyKit.Kit
    private let rateManager: IRateManager

    init(coin: Coin, currencyKit: CurrencyKit.Kit, rateManager: IRateManager) {
        self.coin = coin
        self.currencyKit = currencyKit
        self.rateManager = rateManager
    }

}

extension CoinService {

    var rate: CurrencyValue? {
        let baseCurrency = currencyKit.baseCurrency

        return rateManager.latestRate(coinType: coin.type, currencyCode: baseCurrency.code).map { latestRate in
            CurrencyValue(currency: baseCurrency, value: latestRate.rate)
        }
    }

    func coinValue(value: BigUInt) -> CoinValue {
        let decimalValue = Decimal(bigUInt: value, decimal: coin.decimal) ?? 0
        return CoinValue(coin: coin, value: decimalValue)
    }

    // Example: Dollar, Bitcoin, Ether, etc
    func monetaryValue(value: BigUInt) -> Decimal {
        coinValue(value: value).value
    }

    // Example: Cent, Satoshi, GWei, etc
    func fractionalMonetaryValue(value: Decimal) -> BigUInt {
        BigUInt(value.roundedString(decimal: coin.decimal)) ?? 0
    }

    func amountData(value: Decimal) -> AmountData {
        let primaryInfo: AmountInfo
        var secondaryInfo: AmountInfo?

        let coinValue = CoinValue(coin: coin, value: value)

        if let rate = rate {
            primaryInfo = .coinValue(coinValue: coinValue)
            secondaryInfo = .currencyValue(currencyValue: CurrencyValue(currency: rate.currency, value: rate.value * value))
        } else {
            primaryInfo = .coinValue(coinValue: coinValue)
        }

        return AmountData(primary: primaryInfo, secondary: secondaryInfo)
    }

    func amountData(value: BigUInt) -> AmountData {
        amountData(value: Decimal(bigUInt: value, decimal: coin.decimal) ?? 0)
    }

}
