import BitcoinCore
import RxSwift
import RxRelay
import EthereumKit

class AdapterFactory {
    private let appConfigProvider: AppConfigProvider
    private let ethereumKitManager: EvmKitManager
    private let binanceSmartChainKitManager: EvmKitManager
    private let binanceKitManager: BinanceKitManager
    private let initialSyncSettingsManager: InitialSyncSettingsManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let coinManager: CoinManager

    init(appConfigProvider: AppConfigProvider, ethereumKitManager: EvmKitManager, binanceSmartChainKitManager: EvmKitManager, binanceKitManager: BinanceKitManager, initialSyncSettingsManager: InitialSyncSettingsManager, restoreSettingsManager: RestoreSettingsManager, coinManager: CoinManager) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
        self.binanceKitManager = binanceKitManager
        self.initialSyncSettingsManager = initialSyncSettingsManager
        self.restoreSettingsManager = restoreSettingsManager
        self.coinManager = coinManager
    }

    private func syncMode(wallet: Wallet) -> SyncMode {
        initialSyncSettingsManager.setting(coinType: wallet.coinType, accountOrigin: wallet.account.origin)?.syncMode ?? .fast
    }

}

extension AdapterFactory {

    func ethereumTransactionsAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
        if let evmKit = try? ethereumKitManager.evmKit(account: transactionSource.account),
           let baseCoin = try? coinManager.platformCoin(coinType: .ethereum) {
            return EvmTransactionsAdapter(evmKit: evmKit, source: transactionSource, baseCoin: baseCoin, coinManager: coinManager)
        }

        return nil
    }

    func bscTransactionsAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
        if let evmKit = try? binanceSmartChainKitManager.evmKit(account: transactionSource.account),
           let baseCoin = try? coinManager.platformCoin(coinType: .binanceSmartChain) {
            return EvmTransactionsAdapter(evmKit: evmKit, source: transactionSource, baseCoin: baseCoin, coinManager: coinManager)
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
        case .ethereum:
            if let evmKit = try? ethereumKitManager.evmKit(account: wallet.account) {
                return EvmAdapter(evmKit: evmKit)
            }
        case let .erc20(address):
            if let evmKit = try? ethereumKitManager.evmKit(account: wallet.account),
               let baseCoin = try? coinManager.platformCoin(coinType: .ethereum) {
                return try? Evm20Adapter(evmKit: evmKit, contractAddress: address, wallet: wallet, baseCoin: baseCoin, coinManager: coinManager)
            }
        case .binanceSmartChain:
            if let evmKit = try? binanceSmartChainKitManager.evmKit(account: wallet.account) {
                return EvmAdapter(evmKit: evmKit)
            }
        case let .bep20(address):
            if let evmKit = try? binanceSmartChainKitManager.evmKit(account: wallet.account),
               let baseCoin = try? coinManager.platformCoin(coinType: .binanceSmartChain) {
                return try? Evm20Adapter(evmKit: evmKit, contractAddress: address, wallet: wallet, baseCoin: baseCoin, coinManager: coinManager)
            }
        default: ()
        }

        return nil
    }

}
