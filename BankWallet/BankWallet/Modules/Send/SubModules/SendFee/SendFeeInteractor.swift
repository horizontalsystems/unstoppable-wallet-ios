class SendFeeInteractor {
    private let rateStorage: IRateStorage
    private let currencyManager: ICurrencyManager
    private let feeCoinProvider: IFeeCoinProvider

    init(rateStorage: IRateStorage, currencyManager: ICurrencyManager, feeCoinProvider: IFeeCoinProvider) {
        self.rateStorage = rateStorage
        self.currencyManager = currencyManager
        self.feeCoinProvider = feeCoinProvider
    }

}

extension SendFeeInteractor: ISendFeeInteractor {

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    func rate(coinCode: CoinCode, currencyCode: String) -> Rate? {
        return rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode)
    }

    func feeCoin(coin: Coin) -> Coin? {
        return feeCoinProvider.feeCoin(coin: coin)
    }

    func feeCoinProtocol(coin: Coin) -> String? {
        return feeCoinProvider.feeCoinProtocol(coin: coin)
    }

}
