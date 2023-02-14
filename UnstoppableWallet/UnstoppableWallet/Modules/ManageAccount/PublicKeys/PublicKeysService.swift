class PublicKeysService {
    private let account: Account

    init(account: Account) {
        self.account = account
    }

}

extension PublicKeysService {

    var accountType: AccountType {
        account.type
    }

    var evmAddressSupported: Bool {
        switch account.type {
        case .mnemonic, .evmPrivateKey, .evmAddress: return true
        default: return false
        }
    }

    var accountExtendedPublicKeySupported: Bool {
        switch account.type {
        case .mnemonic, .hdExtendedKey: return true
        default: return false
        }
    }

}
