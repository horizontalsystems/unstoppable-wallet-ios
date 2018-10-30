import RxSwift

class CurrencyManager {
    var subject = PublishSubject<Currency>()

    private let currencies = [
        Currency(code: "USD", localeId: "en_US"),
        Currency(code: "RUB", localeId: "ru_RU")
    ]
}

extension CurrencyManager: ICurrencyManager {

    var baseCurrency: Currency {
        return currencies[0]
    }

}
