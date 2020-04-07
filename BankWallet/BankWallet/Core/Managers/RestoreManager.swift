class RestoreManager {
    private let walletManager: IWalletManager
    private let accountCreator: IAccountCreator
    private let accountManager: IAccountManager

    init(walletManager: IWalletManager, accountCreator: IAccountCreator, accountManager: IAccountManager) {
        self.walletManager = walletManager
        self.accountCreator = accountCreator
        self.accountManager = accountManager
    }

}

extension RestoreManager: IRestoreManager {

    func createAccount(accountType: AccountType, coins: [Coin]) {
        let account = accountCreator.restoredAccount(accountType: accountType)
        accountManager.save(account: account)

        guard !coins.isEmpty else {
            return
        }

        let wallets: [Wallet] = coins.map { coin in
            Wallet(coin: coin, account: account)
        }
        walletManager.save(wallets: wallets)
    }

}
