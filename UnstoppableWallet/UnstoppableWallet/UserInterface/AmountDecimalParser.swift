import Foundation

class AmountDecimalParser {

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

}

extension AmountDecimalParser: IAmountDecimalParser {

    func parseAnyDecimal(from string: String?) -> Decimal? {
        if let string = string {
            for localeIdentifier in Locale.availableIdentifiers {
                formatter.locale = Locale(identifier: localeIdentifier)
                if formatter.number(from: "0\(string)") == nil {
                    continue
                }

                let string = string.replacingOccurrences(of: formatter.decimalSeparator, with: ".")
                if let decimal = Decimal(string: string) {
                    return decimal
                }
            }
        }
        return nil
    }

}
