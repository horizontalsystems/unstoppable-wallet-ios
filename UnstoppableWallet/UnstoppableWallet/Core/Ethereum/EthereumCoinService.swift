import CurrencyKit
import BigInt

class EthereumCoinService {
    private let appConfigProvider: IAppConfigProvider
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager

    init(appConfigProvider: IAppConfigProvider, currencyKit: ICurrencyKit, rateManager: IRateManager) {
        self.appConfigProvider = appConfigProvider
        self.currencyKit = currencyKit
        self.rateManager = rateManager
    }

}

extension EthereumCoinService {

    var ethereumCoin: Coin {
        appConfigProvider.ethereumCoin
    }

    var ethereumRate: CurrencyValue? {
        let baseCurrency = currencyKit.baseCurrency

        return rateManager.marketInfo(coinCode: ethereumCoin.code, currencyCode: baseCurrency.code).map { marketInfo in
            CurrencyValue(currency: baseCurrency, value: marketInfo.rate)
        }
    }

    func amountData(value: BigUInt) -> AmountData {
        let primaryInfo: AmountInfo
        var secondaryInfo: AmountInfo?

        let decimalValue = Decimal(bigUInt: value, decimal: ethereumCoin.decimal) ?? 0
        let coinValue = CoinValue(coin: ethereumCoin, value: decimalValue)

        if let rate = ethereumRate {
            primaryInfo = .coinValue(coinValue: coinValue)
            secondaryInfo = .currencyValue(currencyValue: CurrencyValue(currency: rate.currency, value: rate.value * decimalValue))
        } else {
            primaryInfo = .coinValue(coinValue: coinValue)
        }

        return AmountData(primary: primaryInfo, secondary: secondaryInfo)
    }

}
