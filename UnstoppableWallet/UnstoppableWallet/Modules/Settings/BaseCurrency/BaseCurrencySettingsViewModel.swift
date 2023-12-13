import Combine

class BaseCurrencySettingsViewModel: ObservableObject {
    private let currencyManager = App.shared.currencyManager

    var baseCurrency: Currency {
        didSet {
            currencyManager.baseCurrency = baseCurrency
        }
    }

    let popularCurrencies: [Currency]
    let otherCurrencies: [Currency]

    init() {
        baseCurrency = currencyManager.baseCurrency
        popularCurrencies = currencyManager.popularCurrencies
        otherCurrencies = currencyManager.otherCurrencies
    }
}
