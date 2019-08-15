class SendAmountInteractor {
    private let localStorage: ILocalStorage
    private let rateStorage: IRateStorage
    private let currencyManager: ICurrencyManager

    init(localStorage: ILocalStorage, rateStorage: IRateStorage, currencyManager: ICurrencyManager) {
        self.localStorage = localStorage
        self.rateStorage = rateStorage
        self.currencyManager = currencyManager
    }

}

extension SendAmountInteractor: ISendAmountInteractor {

    var defaultInputType: SendInputType {
        return localStorage.sendInputType ?? .coin
    }

    func set(inputType: SendInputType) {
        localStorage.sendInputType = inputType
    }

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    func rate(coinCode: CoinCode, currencyCode: String) -> Rate? {
        return rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode)
    }

}
