class SendFeeInteractor {
    private let rateStorage: IRateStorage

    init(rateStorage: IRateStorage) {
        self.rateStorage = rateStorage
    }

}

extension SendFeeInteractor: ISendFeeInteractor {

    func rate(coinCode: CoinCode, currencyCode: String) -> Rate? {
        return rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode)
    }

}