class PrivateKeysService {
    private let account: Account
    private let passcodeManager: PasscodeManager

    init(account: Account, passcodeManager: PasscodeManager) {
        self.account = account
        self.passcodeManager = passcodeManager
    }
}

extension PrivateKeysService {
    var isPasscodeSet: Bool {
        passcodeManager.isPasscodeSet
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
        case let .hdExtendedKey(key):
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
        case let .hdExtendedKey(key):
            switch key {
            case .private: return true
            default: return false
            }
        default: return false
        }
    }
}
