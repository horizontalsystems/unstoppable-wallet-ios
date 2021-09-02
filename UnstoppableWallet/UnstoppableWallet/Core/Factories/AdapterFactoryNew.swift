import BitcoinCore
import RxSwift
import RxRelay
import EthereumKit

class AdapterFactoryNew {
    private let appConfigProvider: IAppConfigProvider
    private let ethereumKitManager: EvmKitManager
    private let binanceSmartChainKitManager: EvmKitManager
    private let binanceKitManager: BinanceKitManager
    private let initialSyncSettingsManager: InitialSyncSettingsManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let coinManager: CoinManagerNew

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EvmKitManager, binanceSmartChainKitManager: EvmKitManager, binanceKitManager: BinanceKitManager, initialSyncSettingsManager: InitialSyncSettingsManager, restoreSettingsManager: RestoreSettingsManager, coinManager: CoinManagerNew) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
        self.binanceKitManager = binanceKitManager
        self.initialSyncSettingsManager = initialSyncSettingsManager
        self.restoreSettingsManager = restoreSettingsManager
        self.coinManager = coinManager
    }

    private func syncMode(wallet: WalletNew) -> SyncMode {
        initialSyncSettingsManager.setting(coinType: wallet.coinType, accountOrigin: wallet.account.origin)?.syncMode ?? .fast
    }

}

extension AdapterFactoryNew {

//    func ethereumTransactionsAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
//        (try? ethereumKitManager.evmKit(account: transactionSource.account)).flatMap { evmKit in
//            EvmTransactionsAdapter(evmKit: evmKit, source: transactionSource, coinManager: coinManager)
//        }
//    }
//
//    func bscTransactionsAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
//        (try? binanceSmartChainKitManager.evmKit(account: transactionSource.account)).flatMap { evmKit in
//            EvmTransactionsAdapter(evmKit: evmKit, source: transactionSource, coinManager: coinManager)
//        }
//    }

    func adapter(wallet: WalletNew) -> IAdapter? {
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
                return BinanceAdapter(binanceKit: binanceKit, symbol: symbol, feePlatformCoin: feePlatformCoin, wallet: wallet)
            }
        default: ()
//        case .ethereum:
//            if let evmKit = try? ethereumKitManager.evmKit(account: wallet.account) {
//                return EvmAdapter(evmKit: evmKit)
//            }
//        case let .erc20(address):
//            if let evmKit = try? ethereumKitManager.evmKit(account: wallet.account) {
//                return try? Evm20Adapter(evmKit: evmKit, contractAddress: address, wallet: wallet, coinManager: coinManager)
//            }
//        case .binanceSmartChain:
//            if let evmKit = try? binanceSmartChainKitManager.evmKit(account: wallet.account) {
//                return EvmAdapter(evmKit: evmKit)
//            }
//        case let .bep20(address):
//            if let evmKit = try? binanceSmartChainKitManager.evmKit(account: wallet.account) {
//                return try? Evm20Adapter(evmKit: evmKit, contractAddress: address, wallet: wallet, coinManager: coinManager)
//            }
//        case .unsupported:
//            ()
        }

        return nil
    }

}
