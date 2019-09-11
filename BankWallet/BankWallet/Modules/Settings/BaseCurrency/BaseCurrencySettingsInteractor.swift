class BaseCurrencySettingsInteractor {
    private let currencyManager: ICurrencyManager

    init(currencyManager: ICurrencyManager) {
        self.currencyManager = currencyManager
    }

}

extension BaseCurrencySettingsInteractor: IBaseCurrencySettingsInteractor {

    var baseCurrency: Currency {
        get {
            return currencyManager.baseCurrency
        }
        set {
            currencyManager.baseCurrency = newValue
        }
    }

    var currencies: [Currency] {
        return currencyManager.currencies
    }

}
