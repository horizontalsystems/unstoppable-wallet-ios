class BaseCurrencySettingsInteractor {
    private let currencyManager: ICurrencyManager

    init(currencyManager: ICurrencyManager) {
        self.currencyManager = currencyManager
    }

}

extension BaseCurrencySettingsInteractor: IBaseCurrencySettingsInteractor {

    var currencies: [Currency] {
        return currencyManager.currencies
    }

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    func set(baseCurrency: Currency) {
        currencyManager.set(baseCurrency: baseCurrency)
    }

}
