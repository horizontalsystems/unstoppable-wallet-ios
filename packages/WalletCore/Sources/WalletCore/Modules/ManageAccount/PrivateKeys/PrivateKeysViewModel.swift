struct PrivateKeysViewModel {
    let account: Account
    let showEvmPrivateKey: Bool
    let showTronPrivateKey: Bool
    let showStellarSecretKey: Bool
    let showBip32RootKey: Bool
    let showAccountExtendedPrivateKey: Bool
    let showMoneroPrivateKey: Bool

    init(account: Account) {
        self.account = account

        switch account.type {
        case .mnemonic, .evmPrivateKey: showEvmPrivateKey = true
        default: showEvmPrivateKey = false
        }

        switch account.type {
        case .mnemonic, .trcPrivateKey: showTronPrivateKey = true
        default: showTronPrivateKey = false
        }

        switch account.type {
        case .mnemonic, .stellarSecretKey: showStellarSecretKey = true
        default: showStellarSecretKey = false
        }

        showBip32RootKey = Self.showBip32RootKey(accountType: account.type)
        showAccountExtendedPrivateKey = Self.showAccountExtendedPrivateKey(accountType: account.type)

        switch account.type {
        case .mnemonic: showMoneroPrivateKey = true
        default: showMoneroPrivateKey = false
        }
    }

    var accountType: AccountType {
        account.type
    }

    private static func showBip32RootKey(accountType: AccountType) -> Bool {
        switch accountType {
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

    private static func showAccountExtendedPrivateKey(accountType: AccountType) -> Bool {
        switch accountType {
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
