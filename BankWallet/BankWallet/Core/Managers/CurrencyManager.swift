import RxSwift

class CurrencyManager {
    private let localStorage: ILocalStorage
    private let appConfigProvider: IAppConfigProvider

    let baseCurrencyUpdatedSignal = Signal()

    init(localStorage: ILocalStorage, appConfigProvider: IAppConfigProvider) {
        self.localStorage = localStorage
        self.appConfigProvider = appConfigProvider
    }

}

extension CurrencyManager: ICurrencyManager {

    var currencies: [Currency] {
        return appConfigProvider.currencies
    }

    var baseCurrency: Currency {
        let currencies = appConfigProvider.currencies

        if let storedCode = localStorage.baseCurrencyCode, let currency = currencies.first(where: { $0.code == storedCode }) {
            return currency
        }

        return currencies[0]
    }

    func set(baseCurrency: Currency) {
        localStorage.baseCurrencyCode = baseCurrency.code

        baseCurrencyUpdatedSignal.notify()
    }

}
