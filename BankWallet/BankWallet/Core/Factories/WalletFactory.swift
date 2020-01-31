class WalletFactory: IWalletFactory {

    func wallet(coin: Coin, account: Account, coinSettings: CoinSettings) -> Wallet {
        Wallet(coin: coin, account: account, coinSettings: coinSettings)
    }

}
