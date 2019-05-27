import Foundation

class TransactionsMetadataDataSource {
    private var lastBlockHeights = SynchronizedDictionary<Coin, Int>()
    private var thresholds = SynchronizedDictionary<Coin, Int>()
    private var rates = SynchronizedDictionary<Coin, SynchronizedDictionary<Date, CurrencyValue>>()

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
            rates[coin] = SynchronizedDictionary<Date, CurrencyValue>()
        }

        rates[coin]?[date] = rate
    }

    func clearRates() {
        rates = SynchronizedDictionary<Coin, SynchronizedDictionary<Date, CurrencyValue>>()
    }

}
