import PinKit

class PrivateKeysService {
    private let account: Account
    private let pinKit: IPinKit

    init(account: Account, pinKit: IPinKit) {
        self.account = account
        self.pinKit = pinKit
    }

}

extension PrivateKeysService {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var accountType: AccountType {
        account.type
    }

    var evmPrivateKeySupported: Bool {
        switch account.type {
        case .mnemonic, .evmPrivateKey: return true
        default: return false
        }
    }

    var bip32RootKeySupported: Bool {
        switch account.type {
        case .mnemonic: return true
        case .hdExtendedKey(let key):
            switch key {
            case .private:
                switch key.derivedType {
                case .master: return true
                default: return false
                }
            default: return false
            }
        default: return false
        }
    }

    var accountExtendedPrivateKeySupported: Bool {
        switch account.type {
        case .mnemonic: return true
        case .hdExtendedKey(let key):
            switch key {
            case .private: return true
            default: return false
            }
        default: return false
        }
    }

}
