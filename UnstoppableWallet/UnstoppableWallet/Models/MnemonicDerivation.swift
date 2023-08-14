import MarketKit
import HdWalletKit

enum MnemonicDerivation: String, CaseIterable {
    static let `default` = bip84

    case bip44
    case bip49
    case bip84
    case bip86

    var title: String {
        rawValue.uppercased()
    }

    var addressType: String {
        switch self {
        case .bip44: return "Legacy"
        case .bip49: return "SegWit"
        case .bip84: return "Native SegWit"
        case .bip86: return "Taproot"
        }
    }

    var purpose: Purpose {
        switch self {
        case .bip44: return .bip44
        case .bip49: return .bip49
        case .bip84: return .bip84
        case .bip86: return .bip86
        }
    }

    var derivation: TokenType.Derivation {
        switch self {
        case .bip44: return .bip44
        case .bip49: return .bip49
        case .bip84: return .bip84
        case .bip86: return .bip86
        }
    }

    var order: Int {
        switch self {
        case .bip84: return 0
        case .bip86: return 1
        case .bip49: return 2
        case .bip44: return 3
        }
    }

    var recommended: String {
        self == Self.default ? "blockchain_type.recommended".localized : ""
    }

}

extension Purpose {

    var mnemonicDerivation: MnemonicDerivation {
        switch self {
        case .bip44: return .bip44
        case .bip49: return .bip49
        case .bip84: return .bip84
        case .bip86: return .bip86
        }
    }

}

extension TokenType.Derivation {

    var mnemonicDerivation: MnemonicDerivation {
        switch self {
        case .bip44: return .bip44
        case .bip49: return .bip49
        case .bip84: return .bip84
        case .bip86: return .bip86
        }
    }

}
