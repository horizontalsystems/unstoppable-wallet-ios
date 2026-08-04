import BigInt
import Foundation
import MarketKit

enum ThorChainSendHelper {
    enum Error: Swift.Error, Equatable {
        case invalidAmount
        case excessivePrecision
        case invalidAddress
        case overflow
        case adapterUnavailable
        case expired
        case invalidData
        case submissionUnknown
    }

    static func baseUnits(_ value: Decimal, decimals: Int = 8) throws -> BigUInt {
        guard value.isFinite, value > 0 else { throw Error.invalidAmount }
        var copy = value
        let rendered = NSDecimalString(&copy, Locale(identifier: "en_US_POSIX"))
        let pieces = rendered.split(separator: ".", omittingEmptySubsequences: false)
        guard pieces.count <= 2 else { throw Error.invalidAmount }
        let integer = pieces[0]
        var fraction = pieces.count == 2 ? String(pieces[1]) : ""
        while fraction.last == "0" {
            fraction.removeLast()
        }
        guard fraction.count <= decimals else { throw Error.excessivePrecision }
        let padded = fraction + String(repeating: "0", count: decimals - fraction.count)
        guard let result = BigUInt(String(integer) + padded) else { throw Error.overflow }
        guard var reconstructed = Decimal(
            string: result.description,
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw Error.overflow
        }
        for _ in 0 ..< decimals {
            reconstructed /= 10
        }
        guard reconstructed == value else { throw Error.excessivePrecision }
        return result
    }

    static func caution(_ error: Swift.Error, feeToken: Token) -> CautionNew {
        let text: String
        switch error as? Error {
        case .invalidAmount: text = "Invalid amount"
        case .excessivePrecision: text = "Amount has more than eight decimal places"
        case .invalidAddress: text = "Invalid THORChain address"
        case .expired: text = "Quote expired; refresh to continue"
        case .adapterUnavailable: text = "THORChain is unavailable"
        case .submissionUnknown: text = "Transaction submission is unknown"
        default: text = error.smartDescription
        }
        return CautionNew(title: feeToken.coin.code, text: text, type: .error)
    }
}
