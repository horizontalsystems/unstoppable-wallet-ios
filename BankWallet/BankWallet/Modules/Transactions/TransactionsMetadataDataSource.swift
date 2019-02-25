class TransactionsMetadataDataSource {
    private var lastBlockHeights = [Coin: Int]()
    private var thresholds = [Coin: Int]()
    private var rates = [Coin: [Double: CurrencyValue]]()

    func lastBlockHeight(coin: Coin) -> Int? {
        return lastBlockHeights[coin]
    }

    func threshold(coin: Coin) -> Int? {
        return thresholds[coin]
    }

    func rate(coin: Coin, timestamp: Double) -> CurrencyValue? {
        return rates[coin]?[timestamp]
    }

    func set(lastBlockHeight: Int, coin: Coin) {
        lastBlockHeights[coin] = lastBlockHeight
    }

    func set(threshold: Int, coin: Coin) {
        thresholds[coin] = threshold
    }

    func set(rate: CurrencyValue, coin: Coin, timestamp: Double) {
        if rates[coin] == nil {
            rates[coin] = [Double: CurrencyValue]()
        }

        rates[coin]?[timestamp] = rate
    }

    func clearRates() {
        rates = [:]
    }

}
