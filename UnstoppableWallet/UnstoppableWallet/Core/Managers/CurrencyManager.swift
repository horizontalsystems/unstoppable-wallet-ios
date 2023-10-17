import Combine
import StorageKit

public class CurrencyManager {
    private static let supportedCurrencies = [
        Currency(code: "ARS", symbol: "$",   decimal: 2),
        Currency(code: "AUD", symbol: "A$",  decimal: 2),
        Currency(code: "BRL", symbol: "R$",  decimal: 2),
        Currency(code: "CAD", symbol: "C$",  decimal: 2),
        Currency(code: "CHF", symbol: "₣",   decimal: 2),
        Currency(code: "CNY", symbol: "¥",   decimal: 2),
        Currency(code: "EUR", symbol: "€",   decimal: 2),
        Currency(code: "GBP", symbol: "£",   decimal: 2),
        Currency(code: "HKD", symbol: "HK$", decimal: 2),
        Currency(code: "HUF", symbol: "Ft",  decimal: 2),
        Currency(code: "ILS", symbol: "₪",   decimal: 2),
        Currency(code: "INR", symbol: "₹",   decimal: 2),
        Currency(code: "JPY", symbol: "¥",   decimal: 2),
        Currency(code: "NOK", symbol: "kr",  decimal: 2),
        Currency(code: "PHP", symbol: "₱",   decimal: 2),
        Currency(code: "RON", symbol: "RON", decimal: 2),
        Currency(code: "RUB", symbol: "₽",   decimal: 2),
        Currency(code: "SGD", symbol: "S$",  decimal: 2),
        Currency(code: "USD", symbol: "$",   decimal: 2),
        Currency(code: "ZAR", symbol: "R",   decimal: 2),

        Currency(code: "BTC", symbol: "₿",   decimal: 8),
        Currency(code: "ETH", symbol: "Ξ",   decimal: 8),
        Currency(code: "BNB", symbol: "BNB", decimal: 8),
    ]

    private let keyBaseCurrencyCode = "base_currency_code"

    var currencies: [Currency] { Self.supportedCurrencies }

    private let localStorage: ILocalStorage
    private let subject = PassthroughSubject<Currency, Never>()

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

    var baseCurrency: Currency {
        get {
            if let storedCode: String = localStorage.value(for: keyBaseCurrencyCode), let currency = currencies.first(where: { $0.code == storedCode }) {
                return currency
            }

            return currencies.first(where: { $0.code == "USD" }) ?? currencies[0]
        }
        set {
            localStorage.set(value: newValue.code, for: keyBaseCurrencyCode)
            subject.send(newValue)
        }
    }

    var baseCurrencyUpdatedPublisher: AnyPublisher<Currency, Never> {
        subject.eraseToAnyPublisher()
    }

}
