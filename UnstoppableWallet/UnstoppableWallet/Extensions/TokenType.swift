import MarketKit

extension TokenType {

    var isNative: Bool {
        switch self {
        case .native, .derived, .addressType: return true
        default: return false
        }
    }

    var tokenProtocol: TokenProtocol {
        switch self {
        case .native: return .native
        case .derived: return .native
        case .addressType: return .native
        case .eip20: return .eip20
        case .bep2: return .bep2
        case .spl: return .spl
        case .unsupported: return .unsupported
        }
    }

    var bep2Symbol: String? {
        switch self {
        case .bep2(let symbol): return symbol
        default: return nil
        }
    }

    var order: Int {
        switch self {
        case .native: return 0
        case .derived(let derivation): return derivation.mnemonicDerivation.order
        case .addressType(let type): return type.bitcoinCashCoinType.order
        default: return Int.max
        }
    }

    var derivation: MnemonicDerivation? {
        switch self {
        case .derived(let derivation): return derivation.mnemonicDerivation
        default: return nil
        }
    }

    var bitcoinCashCoinType: BitcoinCashCoinType? {
        switch self {
        case .addressType(let type): return type.bitcoinCashCoinType
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .derived(let derivation): return derivation.mnemonicDerivation.title
        case .addressType(let type): return type.bitcoinCashCoinType.title
        default: return ""
        }
    }

    var description: String {
        switch self {
        case .derived(let derivation): return derivation.mnemonicDerivation.addressType + derivation.mnemonicDerivation.recommended
        case .addressType(let type): return type.bitcoinCashCoinType.description + type.bitcoinCashCoinType.recommended
        default: return ""
        }
    }

    var isDefault: Bool {
        switch self {
        case .derived(let derivation): return derivation.mnemonicDerivation == MnemonicDerivation.default
        case .addressType(let type): return type.bitcoinCashCoinType == BitcoinCashCoinType.default
        default: return false
        }
    }

    var meta: String? {
        switch self {
        case .derived(let derivation): return derivation.rawValue
        case .addressType(let type): return type.rawValue
        case .bep2(let symbol): return symbol
        default: return nil
        }
    }

}
