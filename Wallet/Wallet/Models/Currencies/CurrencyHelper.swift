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

    private lazy var droidCoinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    private let droidFiatFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    func formatCryptoAmount(_ amount: Double) -> String {
        return droidCoinFormatter.string(from: amount as NSNumber) ?? ""
    }

    func formatFiatAmount(_ amount: Double) -> String {
        return droidFiatFormatter.string(from: amount as NSNumber) ?? ""
    }

}
