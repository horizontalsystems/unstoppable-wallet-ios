class Wallet {
    let coin: Coin
    let adapter: IAdapter

    init(coin: Coin, adapter: IAdapter) {
        self.coin = coin
        self.adapter = adapter
    }

}
