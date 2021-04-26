import RxSwift
import RxRelay
import CurrencyKit

class BaseCurrencySettingsService {
    private static let popularCurrencyCodes = ["AUD", "EUR", "USD", "BTC", "ETH", "BNB"]

    private let currencyKit: CurrencyKit.Kit

    let popularCurrencies: [Currency]
    let allCurrencies: [Currency]

    init(currencyKit: CurrencyKit.Kit) {
        self.currencyKit = currencyKit

        var popularCurrencies = [Currency]()
        var allCurrencies = currencyKit.currencies

        for code in BaseCurrencySettingsService.popularCurrencyCodes {
            if let index = allCurrencies.firstIndex(where: { $0.code == code }) {
                popularCurrencies.append(allCurrencies.remove(at: index))
            }
        }

        self.popularCurrencies = popularCurrencies
        self.allCurrencies = allCurrencies
    }

}

extension BaseCurrencySettingsService {

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    func setBaseCurrency(code: String) {
        guard let currency = currencyKit.currencies.first(where: { $0.code == code }) else {
            return
        }

        currencyKit.baseCurrency = currency
    }

}
