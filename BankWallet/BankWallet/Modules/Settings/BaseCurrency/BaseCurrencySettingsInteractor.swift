class BaseCurrencySettingsInteractor {
    weak var delegate: IBaseCurrencySettingsInteractorDelegate?

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

    func setBaseCurrency(code: String) {
        currencyManager.setBaseCurrency(code: code)
        delegate?.didSetBaseCurrency()
    }

}
