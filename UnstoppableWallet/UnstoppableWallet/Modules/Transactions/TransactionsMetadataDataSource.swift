import Foundation
import CurrencyKit
import CoinKit

class TransactionsMetadataDataSource {
    private var lastBlockInfos = SynchronizedDictionary<Wallet, LastBlockInfo>()
    private var rates = SynchronizedDictionary<Coin, SynchronizedDictionary<Date, CurrencyValue>>()

    func lastBlockInfo(wallet: Wallet) -> LastBlockInfo? {
        lastBlockInfos[wallet]
    }

    func rate(coin: Coin, date: Date) -> CurrencyValue? {
        rates[coin]?[date]
    }

    func set(lastBlockInfo: LastBlockInfo, wallet: Wallet) {
        lastBlockInfos[wallet] = lastBlockInfo
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
