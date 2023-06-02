import HdWalletKit

class Account {
    let id: String
    var name: String
    let type: AccountType
    let origin: AccountOrigin
    var backedUp: Bool

    init(id: String, name: String, type: AccountType, origin: AccountOrigin, backedUp: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.origin = origin
        self.backedUp = backedUp
    }

    var watchAccount: Bool {
        switch type {
        case .evmAddress, .tronAddress:
            return true
        case .hdExtendedKey(let key):
            switch key {
            case .public: return true
            default: return false
            }
        default:
            return false
        }
    }

    var nonStandard: Bool {
        guard case .mnemonic(_, _, let bip39Compliant) = type else {
            return false
        }

        return !bip39Compliant
    }

    var nonRecommended: Bool {
        guard case .mnemonic(let words, let salt, let bip39Compliant) = type, bip39Compliant else {
            return false
        }

        return !(Mnemonic.language(words: words) == Mnemonic.Language.english && PassphraseValidator.validate(text: salt))
    }

    var canBeBackedUp: Bool {
        switch type {
        case .mnemonic: return true
        case .hdExtendedKey, .evmAddress, .tronAddress, .evmPrivateKey: return false
        }
    }

}

extension Account: Hashable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

enum AccountOrigin: String {
    case created
    case restored
}
