import CurrencyKit
import BigInt

class CoinService {
    let coin: Coin
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager

    init(coin: Coin, currencyKit: ICurrencyKit, rateManager: IRateManager) {
        self.coin = coin
        self.currencyKit = currencyKit
        self.rateManager = rateManager
    }

}

extension CoinService {

    var rate: CurrencyValue? {
        let baseCurrency = currencyKit.baseCurrency

        return rateManager.marketInfo(coinCode: coin.code, currencyCode: baseCurrency.code).map { marketInfo in
            CurrencyValue(currency: baseCurrency, value: marketInfo.rate)
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

    func amountData(value: BigUInt) -> AmountData {
        let primaryInfo: AmountInfo
        var secondaryInfo: AmountInfo?

        let decimalValue = Decimal(bigUInt: value, decimal: coin.decimal) ?? 0
        let coinValue = CoinValue(coin: coin, value: decimalValue)

        if let rate = rate {
            primaryInfo = .coinValue(coinValue: coinValue)
            secondaryInfo = .currencyValue(currencyValue: CurrencyValue(currency: rate.currency, value: rate.value * decimalValue))
        } else {
            primaryInfo = .coinValue(coinValue: coinValue)
        }

        return AmountData(primary: primaryInfo, secondary: secondaryInfo)
    }

}
