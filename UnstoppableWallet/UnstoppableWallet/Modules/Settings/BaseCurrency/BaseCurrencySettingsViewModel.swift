import Combine

class BaseCurrencySettingsViewModel: ObservableObject {
    private static let popularCurrencyCodes = ["USD", "EUR", "GBP", "JPY"]
    private static let cryptoCurrencyCodes = ["BTC", "ETH", "BNB"]

    private let currencyManager: CurrencyManager

    var baseCurrency: Currency {
        didSet {
            currencyManager.baseCurrency = baseCurrency
        }
    }

    let popularCurrencies: [Currency]
    let otherCurrencies: [Currency]

    init(currencyManager: CurrencyManager) {
        self.currencyManager = currencyManager

        baseCurrency = currencyManager.baseCurrency

        var popularCurrencies = [Currency]()
        var currencies = currencyManager.currencies

        currencies = currencies.filter { !Self.cryptoCurrencyCodes.contains($0.code) }

        for code in Self.popularCurrencyCodes {
            if let index = currencies.firstIndex(where: { $0.code == code }) {
                popularCurrencies.append(currencies.remove(at: index))
            }
        }

        self.popularCurrencies = popularCurrencies
        otherCurrencies = currencies
    }
}
