import RxSwift
import RxRelay
import CurrencyKit

class BaseCurrencySettingsService {
    private static let popularCurrencyCodes = ["USD", "EUR", "GBP", "JPY"]
    private static let cryptoCurrencyCodes = ["BTC", "ETH", "BNB"]

    private let currencyKit: CurrencyKit.Kit

    let popularCurrencies: [Currency]
    let cryptoCurrencies: [Currency]
    let otherCurrencies: [Currency]

    init(currencyKit: CurrencyKit.Kit) {
        self.currencyKit = currencyKit

        var popularCurrencies = [Currency]()
        let cryptoCurrencies = [Currency]()
        var currencies = currencyKit.currencies

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
        currencyKit.baseCurrency
    }

    func setBaseCurrency(code: String) {
        guard let currency = currencyKit.currencies.first(where: { $0.code == code }) else {
            return
        }

        currencyKit.baseCurrency = currency
    }

}
