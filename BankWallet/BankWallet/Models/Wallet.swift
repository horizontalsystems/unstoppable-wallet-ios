class Wallet {
    let title: String
    let coinCode: CoinCode
    let adapter: IAdapter

    init(title: String, coinCode: CoinCode, adapter: IAdapter) {
        self.title = title
        self.coinCode = coinCode
        self.adapter = adapter
    }

}
