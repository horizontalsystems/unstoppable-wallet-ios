import RxSwift

class CurrencyManager {
    var subject = PublishSubject<Currency>()

    private let localStorage: ILocalStorage
    private let appConfigProvider: IAppConfigProvider

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

    func setBaseCurrency(code: String) {
        localStorage.baseCurrencyCode = code
        subject.onNext(baseCurrency)
    }

}
