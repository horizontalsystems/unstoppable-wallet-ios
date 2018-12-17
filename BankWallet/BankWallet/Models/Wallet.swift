class Wallet {
    let coinCode: CoinCode
    let adapter: IAdapter

    init(coinCode: CoinCode, adapter: IAdapter) {
        self.coinCode = coinCode
        self.adapter = adapter
    }

}
