class ManageWalletsWalletFactory {

    func wallet(coin: Coin, account: Account) -> Wallet {
        return Wallet(coin: coin, account: account, syncMode: account.defaultSyncMode)
    }

    func wallet(coin: Coin, accounts: [Account]) -> Wallet? {
        let suitableAccounts = accounts.filter { account in
            return coin.type.canSupport(accountType: account.type)
        }

        guard let account = suitableAccounts.first else {
            return nil
        }

        return Wallet(coin: coin, account: account, syncMode: account.defaultSyncMode)
    }

}
