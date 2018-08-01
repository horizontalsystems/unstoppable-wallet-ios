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

    private let droidCoinFormatter = NumberFormatter()
    private let droidFiatFormatter = NumberFormatter()

    func formatCryptoAmount(_ amount: Double) -> String {
        droidCoinFormatter.minimumIntegerDigits = 1
        droidCoinFormatter.maximumFractionDigits = 8
        droidCoinFormatter.minimumFractionDigits = 2
        return droidCoinFormatter.string(from: amount as NSNumber) ?? ""
    }

    func formatFiatAmount(_ amount: Double) -> String {
        droidFiatFormatter.maximumFractionDigits = 2
        droidFiatFormatter.minimumFractionDigits = 2
        return droidFiatFormatter.string(from: amount as NSNumber) ?? ""
    }

}
