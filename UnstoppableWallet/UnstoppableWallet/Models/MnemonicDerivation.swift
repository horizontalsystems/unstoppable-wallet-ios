import MarketKit
import HdWalletKit

enum MnemonicDerivation: String, CaseIterable {
    case bip44
    case bip49
    case bip84

    var title: String {
        rawValue.uppercased()
    }

    var addressType: String {
        switch self {
        case .bip44: return "Legacy"
        case .bip49: return "SegWit"
        case .bip84: return "Native SegWit"
        }
    }

    var purpose: Purpose {
        switch self {
        case .bip44: return .bip44
        case .bip49: return .bip49
        case .bip84: return .bip84
        }
    }

    var order: Int {
        switch self {
        case .bip44: return 0
        case .bip49: return 1
        case .bip84: return 2
        }
    }

}

extension Purpose {

    var mnemonicDerivation: MnemonicDerivation {
        switch self {
        case .bip44: return .bip44
        case .bip49: return .bip49
        case .bip84: return .bip84
        }
    }

}
