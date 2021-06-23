import BitcoinCore
import RxSwift
import RxRelay
import EthereumKit

class AdapterFactory {
    private let appConfigProvider: IAppConfigProvider
    private let ethereumKitManager: EvmKitManager
    private let binanceSmartChainKitManager: EvmKitManager
    private let binanceKitManager: BinanceKitManager
    private let initialSyncSettingsManager: InitialSyncSettingsManager
    private let restoreSettingsManager: RestoreSettingsManager

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EvmKitManager, binanceSmartChainKitManager: EvmKitManager, binanceKitManager: BinanceKitManager, initialSyncSettingsManager: InitialSyncSettingsManager, restoreSettingsManager: RestoreSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
        self.binanceKitManager = binanceKitManager
        self.initialSyncSettingsManager = initialSyncSettingsManager
        self.restoreSettingsManager = restoreSettingsManager
    }

    private func syncMode(wallet: Wallet) -> SyncMode {
        initialSyncSettingsManager.setting(coinType: wallet.coin.type, accountOrigin: wallet.account.origin)?.syncMode ?? .fast
    }

}

extension AdapterFactory {

    func adapter(wallet: Wallet) -> IAdapter? {
        switch wallet.coin.type {
        case .bitcoin:
            return try? BitcoinAdapter(wallet: wallet, syncMode: syncMode(wallet: wallet), testMode: appConfigProvider.testMode)
        case .litecoin:
            return try? LitecoinAdapter(wallet: wallet, syncMode: syncMode(wallet: wallet), testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            return try? BitcoinCashAdapter(wallet: wallet, syncMode: syncMode(wallet: wallet), testMode: appConfigProvider.testMode)
        case .dash:
            return try? DashAdapter(wallet: wallet, syncMode: syncMode(wallet: wallet), testMode: appConfigProvider.testMode)
        case .zcash:
            let restoreSettings = restoreSettingsManager.settings(account: wallet.account, coinType: wallet.coin.type)
            return try? ZcashAdapter(wallet: wallet, restoreSettings: restoreSettings, testMode: appConfigProvider.testMode)
        case .ethereum:
            if let evmKit = try? ethereumKitManager.evmKit(account: wallet.account) {
                return EvmAdapter(evmKit: evmKit)
            }
        case let .erc20(address):
            if let evmKit = try? ethereumKitManager.evmKit(account: wallet.account) {
                return try? Evm20Adapter(evmKit: evmKit, contractAddress: address, decimal: wallet.coin.decimal)
            }
        case .binanceSmartChain:
            if let evmKit = try? binanceSmartChainKitManager.evmKit(account: wallet.account) {
                return EvmAdapter(evmKit: evmKit)
            }
        case let .bep20(address):
            if let evmKit = try? binanceSmartChainKitManager.evmKit(account: wallet.account) {
                return try? Evm20Adapter(evmKit: evmKit, contractAddress: address, decimal: wallet.coin.decimal)
            }
        case let .bep2(symbol):
            if let binanceKit = try? binanceKitManager.binanceKit(account: wallet.account) {
                return BinanceAdapter(binanceKit: binanceKit, symbol: symbol)
            }
        case .unsupported:
            ()
        }

        return nil
    }

}
