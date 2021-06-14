import BitcoinCore
import RxSwift
import RxRelay
import EthereumKit

class AdapterProviderFactory {
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

}

extension AdapterProviderFactory {

    func adapterProvider(wallet: Wallet) -> IAdapterProvider {
        switch wallet.coin.type {
        case .bitcoin:
            return BitcoinAdapterProvider(wallet: wallet, appConfigProvider: appConfigProvider, initialSyncSettingsManager: initialSyncSettingsManager)
        case .litecoin:
            return LitecoinAdapterProvider(wallet: wallet, appConfigProvider: appConfigProvider, initialSyncSettingsManager: initialSyncSettingsManager)
        case .bitcoinCash:
            return BitcoinCashAdapterProvider(wallet: wallet, appConfigProvider: appConfigProvider, initialSyncSettingsManager: initialSyncSettingsManager)
        case .dash:
            return DashAdapterProvider(wallet: wallet, appConfigProvider: appConfigProvider, initialSyncSettingsManager: initialSyncSettingsManager)
        case .zcash:
            return ZcashAdapterProvider(wallet: wallet, appConfigProvider: appConfigProvider, restoreSettingsManager: restoreSettingsManager)
        case .ethereum:
            return EvmAdapterProvider(wallet: wallet, evmKitManager: ethereumKitManager)
        case let .erc20(address):
            return Eip20AdapterProvider(wallet: wallet, contractAddress: address, evmKitManager: ethereumKitManager)
        case .binanceSmartChain:
            return EvmAdapterProvider(wallet: wallet, evmKitManager: binanceSmartChainKitManager)
        case let .bep20(address):
            return Eip20AdapterProvider(wallet: wallet, contractAddress: address, evmKitManager: binanceSmartChainKitManager)
        case let .bep2(symbol):
            return BinanceAdapterProvider(wallet: wallet, symbol: symbol, binanceKitManager: binanceKitManager)
        case .unsupported:
            return UnsupportedAdapterProvider()
        }
    }

}
