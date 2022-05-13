import BitcoinCore
import RxSwift
import RxRelay
import EthereumKit
import MarketKit

class AdapterFactory {
    private let appConfigProvider: AppConfigProvider
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let binanceKitManager: BinanceKitManager
    private let btcBlockchainManager: BtcBlockchainManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let coinManager: CoinManager
    private let evmLabelManager: EvmLabelManager

    init(appConfigProvider: AppConfigProvider, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager, binanceKitManager: BinanceKitManager, btcBlockchainManager: BtcBlockchainManager, restoreSettingsManager: RestoreSettingsManager, coinManager: CoinManager, evmLabelManager: EvmLabelManager) {
        self.appConfigProvider = appConfigProvider
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.binanceKitManager = binanceKitManager
        self.btcBlockchainManager = btcBlockchainManager
        self.restoreSettingsManager = restoreSettingsManager
        self.coinManager = coinManager
        self.evmLabelManager = evmLabelManager
    }

    private func evmAdapter(wallet: Wallet) -> IAdapter? {
        guard let blockchain = evmBlockchainManager.blockchain(coinType: wallet.coinType) else {
            return nil
        }
        guard let evmKitWrapper = try? evmBlockchainManager.evmKitManager(blockchain: blockchain).evmKitWrapper(account: wallet.account, blockchain: blockchain) else {
            return nil
        }

        return EvmAdapter(evmKitWrapper: evmKitWrapper)
    }

    private func evm20Adapter(address: String, wallet: Wallet, coinManager: CoinManager) -> IAdapter? {
        guard let blockchain = evmBlockchainManager.blockchain(coinType: wallet.coinType) else {
            return nil
        }
        guard let evmKitWrapper = try? evmBlockchainManager.evmKitManager(blockchain: blockchain).evmKitWrapper(account: wallet.account, blockchain: blockchain) else {
            return nil
        }
        guard let baseCoin = evmBlockchainManager.basePlatformCoin(blockchain: blockchain) else {
            return nil
        }

        return try? Evm20Adapter(evmKitWrapper: evmKitWrapper, contractAddress: address, wallet: wallet, baseCoin: baseCoin, coinManager: coinManager, evmLabelManager: evmLabelManager)
    }

}

extension AdapterFactory {

    func evmTransactionsAdapter(transactionSource: TransactionSource, blockchain: EvmBlockchain) -> ITransactionsAdapter? {
        if let evmKitWrapper = try? evmBlockchainManager.evmKitManager(blockchain: blockchain).evmKitWrapper(account: transactionSource.account, blockchain: blockchain),
           let baseCoin = evmBlockchainManager.basePlatformCoin(blockchain: blockchain) {
            let syncSource = evmSyncSourceManager.syncSource(blockchain: blockchain)
            return EvmTransactionsAdapter(evmKitWrapper: evmKitWrapper, source: transactionSource, baseCoin: baseCoin, evmTransactionSource: syncSource.transactionSource, coinManager: coinManager, evmLabelManager: evmLabelManager)
        }

        return nil
    }

    func adapter(wallet: Wallet) -> IAdapter? {
        switch wallet.coinType {
        case .bitcoin:
            let syncMode = btcBlockchainManager.syncMode(blockchain: .bitcoin, accountOrigin: wallet.account.origin)
            return try? BitcoinAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            let syncMode = btcBlockchainManager.syncMode(blockchain: .bitcoinCash, accountOrigin: wallet.account.origin)
            return try? BitcoinCashAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)
        case .litecoin:
            let syncMode = btcBlockchainManager.syncMode(blockchain: .litecoin, accountOrigin: wallet.account.origin)
            return try? LitecoinAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)
        case .dash:
            let syncMode = btcBlockchainManager.syncMode(blockchain: .dash, accountOrigin: wallet.account.origin)
            return try? DashAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)
        case .zcash:
            let restoreSettings = restoreSettingsManager.settings(account: wallet.account, coinType: wallet.coinType)
            return try? ZcashAdapter(wallet: wallet, restoreSettings: restoreSettings, testMode: appConfigProvider.testMode)
        case let .bep2(symbol):
            if let binanceKit = try? binanceKitManager.binanceKit(account: wallet.account), let feePlatformCoin = try? coinManager.platformCoin(coinType: .bep2(symbol: "BNB")) {
                return BinanceAdapter(binanceKit: binanceKit, symbol: symbol, feeCoin: feePlatformCoin, wallet: wallet)
            }
        case .ethereum, .binanceSmartChain, .polygon, .ethereumOptimism, .ethereumArbitrumOne:
            return evmAdapter(wallet: wallet)
        case let .erc20(address):
            return evm20Adapter(address: address, wallet: wallet, coinManager: coinManager)
        case let .bep20(address):
            return evm20Adapter(address: address, wallet: wallet, coinManager: coinManager)
        case let .mrc20(address):
            return evm20Adapter(address: address, wallet: wallet, coinManager: coinManager)
        case let .optimismErc20(address):
            return evm20Adapter(address: address, wallet: wallet, coinManager: coinManager)
        case let .arbitrumOneErc20(address):
            return evm20Adapter(address: address, wallet: wallet, coinManager: coinManager)
        default: ()
        }

        return nil
    }

}
