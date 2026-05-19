import HdWalletKit
import WalletCore

extension Account {
    var watchAccount: Bool {
        switch type {
        case .evmAddress, .tronAddress, .tonAddress, .stellarAccount, .btcAddress, .moneroWatchAccount:
            return true
        case .passkeyOwned:
            return false
        case let .hdExtendedKey(key):
            switch key {
            case .public: return true
            default: return false
            }
        default:
            return false
        }
    }

    var nonStandard: Bool {
        guard case let .mnemonic(_, _, bip39Compliant) = type else {
            return false
        }

        return !bip39Compliant
    }

    var nonRecommended: Bool {
        guard case let .mnemonic(words, salt, bip39Compliant) = type, bip39Compliant else {
            return false
        }

        return !(Mnemonic.language(words: words) == Mnemonic.Language.english && PassphraseValidator.validate(text: salt))
    }

    var canBeBackedUp: Bool {
        switch type {
        case .mnemonic: return true
        default: return false
        }
    }
}
