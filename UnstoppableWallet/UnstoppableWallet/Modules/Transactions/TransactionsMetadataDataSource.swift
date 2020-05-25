import Foundation
import CurrencyKit

class TransactionsMetadataDataSource {
    private var lastBlockInfos = SynchronizedDictionary<Wallet, LastBlockInfo>()
    private var thresholds = SynchronizedDictionary<Wallet, Int>()
    private var rates = SynchronizedDictionary<Coin, SynchronizedDictionary<Date, CurrencyValue>>()

    func lastBlockInfo(wallet: Wallet) -> LastBlockInfo? {
        lastBlockInfos[wallet]
    }

    func threshold(wallet: Wallet) -> Int? {
        thresholds[wallet]
    }

    func rate(coin: Coin, date: Date) -> CurrencyValue? {
        rates[coin]?[date]
    }

    func set(lastBlockInfo: LastBlockInfo, wallet: Wallet) {
        lastBlockInfos[wallet] = lastBlockInfo
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
