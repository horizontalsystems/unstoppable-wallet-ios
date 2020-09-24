import Foundation
import CurrencyKit

class TransactionInfoInteractor {
    private let adapter: ITransactionsAdapter
    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit
    private let feeCoinProvider: IFeeCoinProvider
    private let pasteboardManager: IPasteboardManager

    init(adapter: ITransactionsAdapter, rateManager: IRateManager, currencyKit: ICurrencyKit, feeCoinProvider: IFeeCoinProvider, pasteboardManager: IPasteboardManager) {
        self.adapter = adapter
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.feeCoinProvider = feeCoinProvider
        self.pasteboardManager = pasteboardManager
    }

}
extension TransactionInfoInteractor: ITransactionInfoInteractor {

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    var lastBlockInfo: LastBlockInfo? {
        adapter.lastBlockInfo
    }

    func rate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Decimal? {
        rateManager.historicalRate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
    }

    func rawTransaction(hash: String) -> String? {
        adapter.rawTransaction(hash: hash)
    }

    func feeCoin(coin: Coin) -> Coin? {
        feeCoinProvider.feeCoin(coin: coin)
    }

    func copy(value: String) {
        pasteboardManager.set(value: value)
    }

}
