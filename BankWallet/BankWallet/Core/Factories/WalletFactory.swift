class WalletFactory: IWalletFactory {

    func wallet(coin: Coin, account: Account, syncMode: SyncMode?) -> Wallet {
        return Wallet(coin: coin, account: account, syncMode: syncMode)
    }

}
