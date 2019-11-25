class WalletFactory: IWalletFactory {

    func wallet(coin: Coin, account: Account, coinSettings: [CoinSetting: Any]) -> Wallet {
        Wallet(coin: coin, account: account, coinSettings: coinSettings)
    }

}
