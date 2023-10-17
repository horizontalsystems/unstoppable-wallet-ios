import RxSwift
import RxRelay

class BaseCurrencySettingsService {
    private static let popularCurrencyCodes = ["USD", "EUR", "GBP", "JPY"]
    private static let cryptoCurrencyCodes = ["BTC", "ETH", "BNB"]

    private let currencyManager: CurrencyManager

    let popularCurrencies: [Currency]
    let cryptoCurrencies: [Currency]
    let otherCurrencies: [Currency]

    init(currencyManager: CurrencyManager) {
        self.currencyManager = currencyManager

        var popularCurrencies = [Currency]()
        let cryptoCurrencies = [Currency]()
        var currencies = currencyManager.currencies

        for code in BaseCurrencySettingsService.popularCurrencyCodes {
            if let index = currencies.firstIndex(where: { $0.code == code }) {
                popularCurrencies.append(currencies.remove(at: index))
            }
        }

        for code in BaseCurrencySettingsService.cryptoCurrencyCodes {
            if let index = currencies.firstIndex(where: { $0.code == code }) {
//                cryptoCurrencies.append(currencies.remove(at: index))
                _ = currencies.remove(at: index)
            }
        }

        self.popularCurrencies = popularCurrencies
        self.cryptoCurrencies = cryptoCurrencies
        otherCurrencies = currencies
    }

}

extension BaseCurrencySettingsService {

    var baseCurrency: Currency {
        currencyManager.baseCurrency
    }

    func setBaseCurrency(code: String) {
        guard let currency = currencyManager.currencies.first(where: { $0.code == code }) else {
            return
        }

        currencyManager.baseCurrency = currency
    }

}
