import Foundation

class TransactionsMetadataDataSource {
    private var lastBlockHeights = SynchronizedDictionary<Wallet, Int>()
    private var thresholds = SynchronizedDictionary<Wallet, Int>()
    private var rates = SynchronizedDictionary<Coin, SynchronizedDictionary<Date, CurrencyValue>>()

    func lastBlockHeight(wallet: Wallet) -> Int? {
        return lastBlockHeights[wallet]
    }

    func threshold(wallet: Wallet) -> Int? {
        return thresholds[wallet]
    }

    func rate(coin: Coin, date: Date) -> CurrencyValue? {
        return rates[coin]?[date]
    }

    func set(lastBlockHeight: Int, wallet: Wallet) {
        lastBlockHeights[wallet] = lastBlockHeight
    }

    func set(threshold: Int, wallet: Wallet) {
        thresholds[wallet] = threshold
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
