import MarketKit
import HdWalletKit

enum MnemonicDerivation: String, CaseIterable {
    case bip44
    case bip49
    case bip84

    var title: String {
        "coin_settings.derivation.title.\(self)".localized
    }

    var addressType: String {
        switch self {
        case .bip44: return "Legacy"
        case .bip49: return "SegWit"
        case .bip84: return "Native SegWit"
        }
    }

    var description: String {
        switch self {
        case .bip44: return self.rawValue.uppercased()
        case .bip49, .bip84: return "\(self.rawValue.uppercased()) - \(addressType)"
        }
    }

    var purpose: Purpose {
        switch self {
        case .bip44: return .bip44
        case .bip49: return .bip49
        case .bip84: return .bip84
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
