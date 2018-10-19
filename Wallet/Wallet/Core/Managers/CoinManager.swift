class CoinManager {

    init() {
    }
}

extension CoinManager: ICoinManager {

    var enabledCoins: [Coin] {
        return ["BTCr", "ETHt"]
    }

}
