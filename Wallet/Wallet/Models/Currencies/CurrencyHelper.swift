import Foundation

class CurrencyHelper {
    static let instance = CurrencyHelper()

    private let _formatter = NumberFormatter()

    func formattedValue(for currencyValue: CurrencyValue) -> String? {
        let formatter = _formatter
        formatter.locale = currencyValue.currency.locale
        formatter.numberStyle = .currency
        return formatter.string(from: currencyValue.value as NSNumber)
    }

}
