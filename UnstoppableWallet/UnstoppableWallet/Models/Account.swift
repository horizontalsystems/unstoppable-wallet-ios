import HdWalletKit

class Account: Identifiable {
    let id: String
    var level: Int
    var name: String
    let type: AccountType
    let origin: AccountOrigin
    var backedUp: Bool
    var fileBackedUp: Bool

    init(id: String, level: Int, name: String, type: AccountType, origin: AccountOrigin, backedUp: Bool, fileBackedUp: Bool) {
        self.id = id
        self.level = level
        self.name = name
        self.type = type
        self.origin = origin
        self.backedUp = backedUp
        self.fileBackedUp = fileBackedUp
    }

    var watchAccount: Bool {
        switch type {
        case .evmAddress, .tronAddress:
            return true
        case let .hdExtendedKey(key):
            switch key {
            case .public: return true
            default: return false
            }
        default:
            return false
        }
    }

    var cexAccount: Bool {
        switch type {
        case .cex: return true
        default: return false
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
        case .hdExtendedKey, .evmAddress, .tronAddress, .evmPrivateKey, .cex: return false
        }
    }
}

extension Account: Hashable {
    public static func == (lhs: Account, rhs: Account) -> Bool {
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
