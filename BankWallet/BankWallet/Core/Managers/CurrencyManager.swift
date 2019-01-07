import RxSwift

class CurrencyManager {
    var subject = PublishSubject<Currency>()

    private var subjectNew = ReplaySubject<Currency>.create(bufferSize: 1)

    private let localStorage: ILocalStorage
    private let appConfigProvider: IAppConfigProvider

    init(localStorage: ILocalStorage, appConfigProvider: IAppConfigProvider) {
        self.localStorage = localStorage
        self.appConfigProvider = appConfigProvider

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.notify(currencyCode: localStorage.baseCurrencyCode)
        }
    }

    private func notify(currencyCode: String?) {
        let currencies = appConfigProvider.currencies
        let currency = currencyCode.map { currencyCode in currencies.first(where: { $0.code == currencyCode }) } ?? currencies.first

        if let currency = currency {
            subjectNew.onNext(currency)
        }
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

    var baseCurrencyObservable: Observable<Currency> {
        return subjectNew.asObservable()
    }

    func setBaseCurrency(code: String) {
        localStorage.baseCurrencyCode = code

        subject.onNext(baseCurrency)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.notify(currencyCode: code)
        }
    }

}
