import Foundation

/// The XRPL Payment `DestinationTag`: a 32-bit unsigned integer field of the transaction itself.
///
/// This is where a counterparty's crediting identifier rides on XRP, and the reason XRP cannot be
/// folded into the memo-carrying chains: an exchange or swap provider reads the tag field, never
/// an XRPL memo. One parser serves the send form, the pre-send handler and the deposit builders,
/// so a value outside the field's range is refused everywhere rather than truncated somewhere.
enum XrpDestinationTag {
    static let max = UInt32.max

    /// The tag `value` denotes, or nil when it is not a whole number within the field's range.
    static func parse(_ value: String) -> UInt32? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.allSatisfy(\.isNumber) else {
            return nil
        }
        return UInt32(trimmed)
    }
}
