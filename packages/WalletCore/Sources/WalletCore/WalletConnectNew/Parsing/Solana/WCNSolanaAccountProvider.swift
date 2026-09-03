class WCNSolanaAccountProvider: ICurrentAddressProvider {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }

    var address: String? {
        accountManager.activeAccount.flatMap { try? SolanaKitManager.address(accountType: $0.type) }
    }
}
