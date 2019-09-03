class SendFeeInteractor {
    private let rateManager: IRateManager
    private let currencyManager: ICurrencyManager
    private let feeCoinProvider: IFeeCoinProvider

    init(rateManager: IRateManager, currencyManager: ICurrencyManager, feeCoinProvider: IFeeCoinProvider) {
        self.rateManager = rateManager
        self.currencyManager = currencyManager
        self.feeCoinProvider = feeCoinProvider
    }

}

extension SendFeeInteractor: ISendFeeInteractor {

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    func rate(coinCode: CoinCode, currencyCode: String) -> Rate? {
        return rateManager.nonExpiredLatestRate(coinCode: coinCode, currencyCode: currencyCode)
    }

    func feeCoin(coin: Coin) -> Coin? {
        return feeCoinProvider.feeCoin(coin: coin)
    }

    func feeCoinProtocol(coin: Coin) -> String? {
        return feeCoinProvider.feeCoinProtocol(coin: coin)
    }

}
