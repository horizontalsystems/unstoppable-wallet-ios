import Foundation
import MarketKit

enum ThorChainSwapMemo {
    static func validate(_ memo: String, expectedDestination: String, blockchainType: BlockchainType) throws {
        // Empty fields are significant: dropping one could mistake the limit for a recipient.
        let fields = memo.components(separatedBy: ":")
        guard fields.count >= 3, ["=", "s", "swap"].contains(fields[0].lowercased()), !fields[1].isEmpty else {
            throw ValidationError.invalidMemo
        }

        var destinationField = fields[2]
        if blockchainType == .bitcoinCash, destinationField.lowercased() == "bitcoincash", fields.count >= 4 {
            destinationField += ":" + fields[3]
        }
        let destination = destinationField.components(separatedBy: "/")[0]
        guard !destination.isEmpty, !expectedDestination.isEmpty else {
            throw ValidationError.invalidMemo
        }
        guard addressesMatch(destination, expectedDestination, blockchainType: blockchainType) else {
            throw ValidationError.destinationMismatch
        }
    }

    private static func addressesMatch(_ actual: String, _ expected: String, blockchainType: BlockchainType) -> Bool {
        if blockchainType.isEvm {
            func isHexAddress(_ address: String) -> Bool {
                address.count == 42 && address.lowercased().hasPrefix("0x") && address.dropFirst(2).allSatisfy { "0123456789abcdefABCDEF".contains($0) }
            }
            return isHexAddress(actual) && isHexAddress(expected) && actual.lowercased() == expected.lowercased()
        }

        if blockchainType == .bitcoinCash {
            func cashPayload(_ address: String) -> String? {
                guard isSingleCase(address) else { return nil }
                let lower = address.lowercased()
                let payload = lower.hasPrefix("bitcoincash:") ? String(lower.dropFirst("bitcoincash:".count)) : lower
                guard payload.hasPrefix("q") || payload.hasPrefix("p"), payload.count == 42,
                      payload.allSatisfy({ bech32Alphabet.contains($0) }) else { return nil }
                return payload
            }
            if let lhs = cashPayload(actual), let rhs = cashPayload(expected) {
                return lhs == rhs
            }
            // CashAddr must not fall through to equality and accept invalid mixed case.
            if actual.lowercased().hasPrefix("bitcoincash:") || expected.lowercased().hasPrefix("bitcoincash:") || actual.lowercased().hasPrefix("q") || actual.lowercased().hasPrefix("p") || expected.lowercased().hasPrefix("q") || expected.lowercased().hasPrefix("p") {
                return false
            }
        }

        let prefixes: [String]
        switch blockchainType {
        case .bitcoin: prefixes = ["bc1"]
        case .litecoin: prefixes = ["ltc1"]
        case .thorChain: prefixes = ["thor1"]
        case .mayaChain: prefixes = ["maya1"]
        case .zcash: prefixes = ["u1", "zs1"]
        default: prefixes = []
        }
        if prefixes.contains(where: { actual.lowercased().hasPrefix($0) || expected.lowercased().hasPrefix($0) }) {
            func normalizedBech32(_ address: String) -> String? {
                guard isSingleCase(address), let prefix = prefixes.first(where: { address.lowercased().hasPrefix($0) }) else { return nil }
                let lower = address.lowercased()
                let payload = lower.dropFirst(prefix.count)
                guard payload.count > 6, payload.allSatisfy({ bech32Alphabet.contains($0) }) else { return nil }
                return lower
            }
            guard let lhs = normalizedBech32(actual), let rhs = normalizedBech32(expected) else { return false }
            return lhs == rhs
        }
        // Legacy BTC/LTC/ZEC and other Base58 addresses are case-sensitive.
        return actual == expected
    }

    private static let bech32Alphabet = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

    private static func isSingleCase(_ value: String) -> Bool {
        value.unicodeScalars.allSatisfy(\.isASCII) && (value == value.lowercased() || value == value.uppercased())
    }

    enum ValidationError: Error, LocalizedError, Equatable {
        case invalidMemo
        case destinationMismatch

        var errorDescription: String? {
            switch self {
            case .invalidMemo: "swap.error.invalid_swap_memo".localized
            case .destinationMismatch: "swap.error.memo_recipient_mismatch".localized
            }
        }
    }
}
