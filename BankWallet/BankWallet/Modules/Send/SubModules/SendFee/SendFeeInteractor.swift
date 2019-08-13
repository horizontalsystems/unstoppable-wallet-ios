class SendFeeInteractor {
    private let rateStorage: IRateStorage
    private let currencyManager: ICurrencyManager

    init(rateStorage: IRateStorage, currencyManager: ICurrencyManager) {
        self.rateStorage = rateStorage
        self.currencyManager = currencyManager
    }

}

extension SendFeeInteractor: ISendFeeInteractor {

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    func rate(coinCode: CoinCode, currencyCode: String) -> Rate? {
        return rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode)
    }

}
