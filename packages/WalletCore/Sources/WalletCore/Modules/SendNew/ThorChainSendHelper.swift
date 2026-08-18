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
        guard let result = BigUInt(value.hs.roundedString(decimal: decimals)), result > 0 else {
            throw Error.invalidAmount
        }
        return result
    }

    static func caution(_ error: Swift.Error, feeToken: Token) -> CautionNew {
        let chainName = feeToken.blockchainType == .mayaChain ? "Maya" : "THORChain"
        let text: String
        switch error as? Error {
        case .invalidAmount: text = "Invalid amount"
        case .excessivePrecision: text = "Amount has more than \(feeToken.decimals) decimal places"
        case .invalidAddress: text = "Invalid \(chainName) address"
        case .expired: text = "Quote expired; refresh to continue"
        case .adapterUnavailable: text = "\(chainName) is unavailable"
        case .submissionUnknown: text = "Transaction submission is unknown"
        default: text = error.smartDescription
        }
        return CautionNew(title: feeToken.coin.code, text: text, type: .error)
    }
}
