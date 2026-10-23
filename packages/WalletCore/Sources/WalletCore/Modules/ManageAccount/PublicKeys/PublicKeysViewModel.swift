struct PublicKeysViewModel {
    let account: Account
    let showEvmAddress: Bool
    let showTronAddress: Bool
    let showAccountExtendedPublicKey: Bool
    let showMoneroPublicKey: Bool

    init(account: Account) {
        self.account = account

        switch account.type {
        case .mnemonic, .passkeyOwned, .evmPrivateKey, .evmAddress: showEvmAddress = true
        default: showEvmAddress = false
        }

        // mirrors the AccountAddress Tron providers (AccountAddressProvider.tronAddress); must stay in sync
        switch account.type {
        case .mnemonic, .trcPrivateKey, .tronAddress: showTronAddress = true
        default: showTronAddress = false
        }

        switch account.type {
        case .mnemonic, .hdExtendedKey: showAccountExtendedPublicKey = true
        default: showAccountExtendedPublicKey = false
        }

        switch account.type {
        case .mnemonic: showMoneroPublicKey = true
        default: showMoneroPublicKey = false
        }
    }

    var accountType: AccountType {
        account.type
    }
}
