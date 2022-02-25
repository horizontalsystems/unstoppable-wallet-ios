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
    private let initialSyncSettingsManager: InitialSyncSettingsManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let coinManager: CoinManager

    init(appConfigProvider: AppConfigProvider, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager, binanceKitManager: BinanceKitManager, initialSyncSettingsManager: InitialSyncSettingsManager, restoreSettingsManager: RestoreSettingsManager, coinManager: CoinManager) {
        self.appConfigProvider = appConfigProvider
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.binanceKitManager = binanceKitManager
        self.initialSyncSettingsManager = initialSyncSettingsManager
        self.restoreSettingsManager = restoreSettingsManager
        self.coinManager = coinManager
    }

    private func syncMode(wallet: Wallet) -> SyncMode {
        initialSyncSettingsManager.setting(coinType: wallet.coinType, accountOrigin: wallet.account.origin)?.syncMode ?? .fast
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

        return try? Evm20Adapter(evmKitWrapper: evmKitWrapper, contractAddress: address, wallet: wallet, baseCoin: baseCoin, coinManager: coinManager)
    }

}

extension AdapterFactory {

    func evmTransactionsAdapter(transactionSource: TransactionSource, blockchain: EvmBlockchain) -> ITransactionsAdapter? {
        if let evmKitWrapper = try? evmBlockchainManager.evmKitManager(blockchain: blockchain).evmKitWrapper(account: transactionSource.account, blockchain: blockchain),
           let baseCoin = evmBlockchainManager.basePlatformCoin(blockchain: blockchain) {
            let syncSource = evmSyncSourceManager.syncSource(account: transactionSource.account, blockchain: blockchain)
            return EvmTransactionsAdapter(evmKitWrapper: evmKitWrapper, source: transactionSource, baseCoin: baseCoin, evmTransactionSource: syncSource.transactionSource, coinManager: coinManager)
        }

        return nil
    }

    func adapter(wallet: Wallet) -> IAdapter? {
        switch wallet.coinType {
        case .bitcoin:
            return try? BitcoinAdapter(wallet: wallet, syncMode: syncMode(wallet: wallet), testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            return try? BitcoinCashAdapter(wallet: wallet, syncMode: syncMode(wallet: wallet), testMode: appConfigProvider.testMode)
        case .litecoin:
            return try? LitecoinAdapter(wallet: wallet, syncMode: syncMode(wallet: wallet), testMode: appConfigProvider.testMode)
        case .dash:
            return try? DashAdapter(wallet: wallet, syncMode: syncMode(wallet: wallet), testMode: appConfigProvider.testMode)
        case .zcash:
            let restoreSettings = restoreSettingsManager.settings(account: wallet.account, coinType: wallet.coinType)
            return try? ZcashAdapter(wallet: wallet, restoreSettings: restoreSettings, testMode: appConfigProvider.testMode)
        case let .bep2(symbol):
            if let binanceKit = try? binanceKitManager.binanceKit(account: wallet.account), let feePlatformCoin = try? coinManager.platformCoin(coinType: .bep2(symbol: "BNB")) {
                return BinanceAdapter(binanceKit: binanceKit, symbol: symbol, feeCoin: feePlatformCoin, wallet: wallet)
            }
        case .ethereum, .binanceSmartChain, .polygon:
            return evmAdapter(wallet: wallet)
        case let .erc20(address):
            return evm20Adapter(address: address, wallet: wallet, coinManager: coinManager)
        case let .bep20(address):
            return evm20Adapter(address: address, wallet: wallet, coinManager: coinManager)
        case let .mrc20(address):
            return evm20Adapter(address: address, wallet: wallet, coinManager: coinManager)
        default: ()
        }

        return nil
    }

}
