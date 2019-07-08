class WalletCreator {
    private let accountManager: IAccountManager
    private let walletFactory: IWalletFactory

    init(accountManager: IAccountManager, walletFactory: IWalletFactory) {
        self.accountManager = accountManager
        self.walletFactory = walletFactory
    }

}

extension WalletCreator: IWalletCreator {

    func wallet(coin: Coin) -> Wallet? {
        let suitableAccounts = accountManager.accounts.filter { account in
            return coin.type.canSupport(accountType: account.type)
        }

        guard let account = suitableAccounts.first else {
            return nil
        }

        return walletFactory.wallet(coin: coin, account: account)
    }

    func wallet(coin: Coin, account: Account) -> Wallet {
        return walletFactory.wallet(coin: coin, account: account)
    }

}
