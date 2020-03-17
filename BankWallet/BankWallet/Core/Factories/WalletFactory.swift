class WalletFactory: IWalletFactory {

    func wallet(coin: Coin, account: Account) -> Wallet {
        Wallet(coin: coin, account: account)
    }

}
