class SendAmountInteractor {
    private let localStorage: ILocalStorage
    private let rateManager: IRateManager
    private let currencyManager: ICurrencyManager

    init(localStorage: ILocalStorage, rateManager: IRateManager, currencyManager: ICurrencyManager) {
        self.localStorage = localStorage
        self.rateManager = rateManager
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
        return rateManager.nonExpiredLatestRate(coinCode: coinCode, currencyCode: currencyCode)
    }

}
