import Foundation
import CurrencyKit
import CoinKit
import EthereumKit

class TransactionInfoInteractor {
    private let adapter: ITransactionsAdapter
    private let rateManager: IRateManager
    private let currencyKit: CurrencyKit.Kit
    private let feeCoinProvider: IFeeCoinProvider
    private let pasteboardManager: IPasteboardManager
    private let appConfigProvider: IAppConfigProvider
    private let accountSettingManager: AccountSettingManager

    init(adapter: ITransactionsAdapter, rateManager: IRateManager, currencyKit: CurrencyKit.Kit, feeCoinProvider: IFeeCoinProvider, pasteboardManager: IPasteboardManager, appConfigProvider: IAppConfigProvider, accountSettingManager: AccountSettingManager) {
        self.adapter = adapter
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.feeCoinProvider = feeCoinProvider
        self.pasteboardManager = pasteboardManager
        self.appConfigProvider = appConfigProvider
        self.accountSettingManager = accountSettingManager
    }

}
extension TransactionInfoInteractor: ITransactionInfoInteractor {

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    var lastBlockInfo: LastBlockInfo? {
        adapter.lastBlockInfo
    }

    var testMode: Bool {
        appConfigProvider.testMode
    }

    func rate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Decimal? {
        rateManager.historicalRate(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)
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

    func ethereumNetworkType(account: Account) -> NetworkType {
        accountSettingManager.ethereumNetwork(account: account).networkType
    }

    func binanceSmartChainNetworkType(account: Account) -> NetworkType {
        accountSettingManager.binanceSmartChainNetwork(account: account).networkType
    }

}
