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

    var baseCurrency: Currency {
        get {
            let currencies = appConfigProvider.currencies

            if let storedCode = localStorage.baseCurrencyCode, let currency = currencies.first(where: { $0.code == storedCode }) {
                return currency
            }

            return currencies[0]
        }
        set {
            localStorage.baseCurrencyCode = newValue.code

            baseCurrencyUpdatedSignal.notify()
        }
    }

    var currencies: [Currency] {
        return appConfigProvider.currencies
    }

}
