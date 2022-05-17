import Foundation

class AmountDecimalParser {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

}

extension AmountDecimalParser {

    func parseAnyDecimal(from string: String?) -> Decimal? {
        if let string = string {
            for localeIdentifier in Locale.availableIdentifiers {
                Self.formatter.locale = Locale(identifier: localeIdentifier)
                if Self.formatter.number(from: "0\(string)") == nil {
                    continue
                }

                let string = string.replacingOccurrences(of: Self.formatter.decimalSeparator, with: ".")
                if let decimal = Decimal(string: string) {
                    return decimal
                }
            }
        }
        return nil
    }

}
