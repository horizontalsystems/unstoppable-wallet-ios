import Foundation

class SendFeeInteractor {
    private let rateManager: IXRateManager
    private let currencyManager: ICurrencyManager
    private let feeCoinProvider: IFeeCoinProvider

    init(rateManager: IXRateManager, currencyManager: ICurrencyManager, feeCoinProvider: IFeeCoinProvider) {
        self.rateManager = rateManager
        self.currencyManager = currencyManager
        self.feeCoinProvider = feeCoinProvider
    }

}

extension SendFeeInteractor: ISendFeeInteractor {

    var baseCurrency: Currency {
        currencyManager.baseCurrency
    }

    func nonExpiredRateValue(coinCode: CoinCode, currencyCode: String) -> Decimal? {
        rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode)?.rate
    }

    func feeCoin(coin: Coin) -> Coin? {
        feeCoinProvider.feeCoin(coin: coin)
    }

    func feeCoinProtocol(coin: Coin) -> String? {
        feeCoinProvider.feeCoinProtocol(coin: coin)
    }

}
