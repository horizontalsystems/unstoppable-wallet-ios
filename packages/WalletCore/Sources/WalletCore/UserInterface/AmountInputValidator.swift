import Foundation

// Validates the text of an amount input field as the user edits it. "." and the locale decimal
// separator are both accepted as the separator, matching `AmountDecimalParser`.
enum AmountInputValidator {
    static let defaultMaxDecimals = 8 // used when no token is selected
    static let fiatMaxDecimals = 2 // fiat field, all currencies

    static var currentDecimalSeparator: String {
        Locale.current.decimalSeparator ?? "."
    }

    enum Outcome: Equatable {
        case valid // accept the new text as-is
        case replaced(String) // accept, but replace the text (leading-zero cleanup / paste trimming and truncation)
        case invalid // reject: revert to the old text
    }

    static func validate(
        oldText: String,
        newText: String,
        maxDecimals: Int,
        decimalSeparator: String = currentDecimalSeparator
    ) -> Outcome {
        guard newText != oldText else {
            return .valid
        }

        if isValid(newText, maxDecimals: maxDecimals, decimalSeparator: decimalSeparator) {
            return .valid
        }

        let (inserted, removed) = editSize(oldText: oldText, newText: newText)

        // Paste or bulk change: trim whitespace, strip redundant leading zeros, then silently truncate extra fraction digits
        if inserted > 1 {
            let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
            let candidate = strippingLeadingZeros(trimmed, decimalSeparator: decimalSeparator)

            if isValid(candidate, maxDecimals: maxDecimals, decimalSeparator: decimalSeparator) {
                return .replaced(candidate)
            }

            if let truncated = truncated(candidate, maxDecimals: maxDecimals, decimalSeparator: decimalSeparator) {
                return .replaced(truncated)
            }

            return .invalid
        }

        // Pure deletion is never rejected. It can leave redundant leading zeros (e.g. "100.5" -> "00.5"), so strip them
        if inserted == 0, removed > 0 {
            let cleaned = strippingLeadingZeros(newText, decimalSeparator: decimalSeparator)
            return cleaned == newText ? .valid : .replaced(cleaned)
        }

        // Single keystroke: a digit typed after a lone zero replaces it ("0" + "5" -> "5"),
        // but a keystroke that only adds a redundant zero ("0" + "0") is rejected
        let cleaned = strippingLeadingZeros(newText, decimalSeparator: decimalSeparator)

        if cleaned != oldText, isValid(cleaned, maxDecimals: maxDecimals, decimalSeparator: decimalSeparator) {
            return .replaced(cleaned)
        }

        return .invalid
    }

    static func isValid(_ text: String, maxDecimals: Int, decimalSeparator: String) -> Bool {
        guard let (integerPart, fractionPart) = split(text, decimalSeparator: decimalSeparator) else {
            return false
        }

        guard isValidIntegerPart(integerPart) else {
            return false
        }

        if let fractionPart {
            return maxDecimals > 0 && fractionPart.count <= maxDecimals
        }

        return true
    }

    // Returns the text with fraction digits cut to `maxDecimals`, or nil if it is invalid for any other reason
    static func truncated(_ text: String, maxDecimals: Int, decimalSeparator: String) -> String? {
        guard let (integerPart, fractionPart) = split(text, decimalSeparator: decimalSeparator), isValidIntegerPart(integerPart) else {
            return nil
        }

        guard let fractionPart else {
            return text
        }

        guard maxDecimals > 0 else {
            return integerPart
        }

        guard fractionPart.count > maxDecimals else {
            return text
        }

        let separatorIndex = text.index(text.startIndex, offsetBy: integerPart.count)
        return String(text[...separatorIndex]) + String(fractionPart.prefix(maxDecimals))
    }

    private static func isSeparator(_ character: Character, decimalSeparator: String) -> Bool {
        character == "." || String(character) == decimalSeparator
    }

    private static func isDigit(_ character: Character) -> Bool {
        ("0" ... "9").contains(character)
    }

    // Splits the text into integer and fraction digits. Returns nil if the text has a non-digit character
    // or more than one separator. The fraction part is nil when there is no separator.
    private static func split(_ text: String, decimalSeparator: String) -> (String, String?)? {
        var integerPart = ""
        var fractionPart: String?

        for character in text {
            if isSeparator(character, decimalSeparator: decimalSeparator) {
                guard fractionPart == nil else {
                    return nil
                }

                fractionPart = ""
            } else if isDigit(character) {
                if fractionPart != nil {
                    fractionPart?.append(character)
                } else {
                    integerPart.append(character)
                }
            } else {
                return nil
            }
        }

        return (integerPart, fractionPart)
    }

    // Empty, exactly "0", or a number without a leading zero
    private static func isValidIntegerPart(_ integerPart: String) -> Bool {
        integerPart.count <= 1 || integerPart.first != "0"
    }

    private static func strippingLeadingZeros(_ text: String, decimalSeparator: String) -> String {
        var result = Substring(text)

        while result.count > 1, result.first == "0" {
            let next = result[result.index(after: result.startIndex)]

            if isSeparator(next, decimalSeparator: decimalSeparator) {
                break
            }

            result = result.dropFirst()
        }

        return String(result)
    }

    private static func editSize(oldText: String, newText: String) -> (inserted: Int, removed: Int) {
        let oldCharacters = Array(oldText)
        let newCharacters = Array(newText)
        let minCount = min(oldCharacters.count, newCharacters.count)

        var prefix = 0
        while prefix < minCount, oldCharacters[prefix] == newCharacters[prefix] {
            prefix += 1
        }

        var suffix = 0
        while suffix < minCount - prefix, oldCharacters[oldCharacters.count - 1 - suffix] == newCharacters[newCharacters.count - 1 - suffix] {
            suffix += 1
        }

        return (newCharacters.count - prefix - suffix, oldCharacters.count - prefix - suffix)
    }
}
