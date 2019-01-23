class TransactionsMetadataDataSource {
    private var lastBlockHeights = [CoinCode: Int]()
    private var thresholds = [CoinCode: Int]()
    private var rates = [CoinCode: [Double: CurrencyValue]]()

    func lastBlockHeight(coinCode: CoinCode) -> Int? {
        return lastBlockHeights[coinCode]
    }

    func threshold(coinCode: CoinCode) -> Int? {
        return thresholds[coinCode]
    }

    func rate(coinCode: CoinCode, timestamp: Double) -> CurrencyValue? {
        return rates[coinCode]?[timestamp]
    }

    func set(lastBlockHeight: Int, coinCode: CoinCode) {
        lastBlockHeights[coinCode] = lastBlockHeight
    }

    func set(threshold: Int, coinCode: CoinCode) {
        thresholds[coinCode] = threshold
    }

    func set(rate: CurrencyValue, coinCode: CoinCode, timestamp: Double) {
        if rates[coinCode] == nil {
            rates[coinCode] = [Double: CurrencyValue]()
        }

        rates[coinCode]?[timestamp] = rate
    }

    func clearRates() {
        rates = [:]
    }

}
