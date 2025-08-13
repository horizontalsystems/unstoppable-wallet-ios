import BigInt
import Foundation
import MarketKit

extension Token {
    var protocolName: String? {
        switch type {
        case .native:
            switch blockchainType {
            case .ethereum, .binanceSmartChain, .tron, .ton: return nil
            default: return blockchain.name
            }
        case .eip20:
            switch blockchainType {
            case .ethereum: return "ERC20"
            case .binanceSmartChain: return "BEP20"
            case .tron: return "TRC20"
            default: return blockchain.name
            }
        case .jetton:
            return "JETTON"
        default:
            return blockchain.name
        }
    }

    var isCustom: Bool {
        coin.uid == tokenQuery.customCoinUid
    }

    var placeholderImageName: String {
        "\(blockchainType.uid)_\(type.tokenProtocol)_32"
    }

    var swappable: Bool {
        BlockchainType.swappable.contains(blockchainType)
    }

    var badge: String? {
        switch type {
        case let .derived(derivation): return derivation.mnemonicDerivation.rawValue.uppercased()
        case let .addressType(type): return type.bitcoinCashCoinType.title
        default: return protocolName
        }
    }

    var fullBadge: String {
        (badge ?? "coin_platforms.native".localized).uppercased()
    }

    var sendToSelfAllowed: Bool {
        if case .native = type, blockchainType == .zcash { return false }
        if blockchainType == .tron { return false }

        return true
    }
}

extension Token: Comparable {
    public static func < (lhs: Token, rhs: Token) -> Bool {
        let lhsTypeOrder = lhs.type.order
        let rhsTypeOrder = rhs.type.order

        guard lhsTypeOrder == rhsTypeOrder else {
            return lhsTypeOrder < rhsTypeOrder
        }

        return lhs.blockchainType.order < rhs.blockchainType.order
    }
}

extension Token {
    func decimalValue(value: BigUInt) -> Decimal {
        Decimal(bigUInt: value, decimals: decimals) ?? 0
    }

    func decimalValue(value: Int) -> Decimal {
        Decimal(sign: value >= 0 ? .plus : .minus, exponent: -decimals, significand: Decimal(value))
    }

    func fractionalMonetaryValue(value: Decimal) -> BigUInt {
        BigUInt(value.hs.roundedString(decimal: decimals)) ?? 0
    }
    
    func rawAmountString(_ amount: Decimal) -> String {
        (amount * pow(10, decimals)).hs.roundedString(decimal: 0)
    }

    func rawAmount(_ amount: Decimal) -> BigUInt? {
        return BigUInt(rawAmountString(amount))
    }

}
