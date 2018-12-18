class Wallet {
    let coinCode: CoinCode
    let title: String
    let adapter: IAdapter

    init(coinCode: CoinCode, title: String, adapter: IAdapter) {
        self.coinCode = coinCode
        self.title = title
        self.adapter = adapter
    }

}
