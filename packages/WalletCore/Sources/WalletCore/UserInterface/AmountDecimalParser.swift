import Foundation

public struct AmountDecimalParser {
    public init() {}

    public func parseAnyDecimal(from string: String?) -> Decimal? {
        guard let string, !string.isEmpty else {
            return nil
        }

        // Normalize the current locale's decimal separator to "." so keypad input parses.
        // "." is also accepted directly (e.g. pasted values), since Decimal(string:) uses it natively.
        let separator = Locale.current.decimalSeparator ?? "."
        let normalized = string.replacingOccurrences(of: separator, with: ".")

        return Decimal(string: normalized)
    }

    public func string(from decimal: Decimal?) -> String {
        guard let decimal else {
            return ""
        }

        let separator = Locale.current.decimalSeparator ?? "."
        return decimal.description.replacingOccurrences(of: ".", with: separator)
    }
}
