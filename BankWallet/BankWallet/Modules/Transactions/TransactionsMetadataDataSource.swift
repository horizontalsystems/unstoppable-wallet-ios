import Foundation

class TransactionsMetadataDataSource {
    private var lastBlockHeights = [Coin: Int]()
    private var thresholds = [Coin: Int]()
    private var rates = [Coin: [Date: CurrencyValue]]()

    func lastBlockHeight(coin: Coin) -> Int? {
        return lastBlockHeights[coin]
    }

    func threshold(coin: Coin) -> Int? {
        return thresholds[coin]
    }

    func rate(coin: Coin, date: Date) -> CurrencyValue? {
        return rates[coin]?[date]
    }

    func set(lastBlockHeight: Int, coin: Coin) {
        lastBlockHeights[coin] = lastBlockHeight
    }

    func set(threshold: Int, coin: Coin) {
        thresholds[coin] = threshold
    }

    func set(rate: CurrencyValue, coin: Coin, date: Date) {
        if rates[coin] == nil {
            rates[coin] = [Date: CurrencyValue]()
        }

        rates[coin]?[date] = rate
    }

    func clearRates() {
        rates = [:]
    }

}
