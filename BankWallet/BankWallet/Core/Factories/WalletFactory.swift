class WalletFactory: IWalletFactory {

    func wallet(coin: Coin, account: Account) -> Wallet {
        return Wallet(coin: coin, account: account, syncMode: account.defaultSyncMode)
    }

}
