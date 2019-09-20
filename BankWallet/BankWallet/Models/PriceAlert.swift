class PriceAlert {
    let coin: Coin
    var state: AlertState

    init(coin: Coin, state: AlertState) {
        self.coin = coin
        self.state = state
    }

}
