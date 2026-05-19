import WalletCore

class PublicKeysService {
    private let account: Account

    init(account: Account) {
        self.account = account
    }
}

extension PublicKeysService {
    var currentAccount: Account {
        account
    }

    var accountType: AccountType {
        account.type
    }

    var evmAddressSupported: Bool {
        switch account.type {
        case .mnemonic, .passkeyOwned, .evmPrivateKey, .evmAddress: return true
        default: return false
        }
    }

    var tronAddressSupported: Bool {
        (try? AccountAddress.tronAddress(account: account)) != nil
    }

    var accountExtendedPublicKeySupported: Bool {
        switch account.type {
        case .mnemonic, .hdExtendedKey: return true
        default: return false
        }
    }

    var moneroPublicKeySupported: Bool {
        switch account.type {
        case .mnemonic: return true
        default: return false
        }
    }
}
