import BitcoinCore

class AdapterFactory: IAdapterFactory {
    weak var derivationSettingsManager: IDerivationSettingsManager?
    weak var initialSyncSettingsManager: IInitialSyncSettingsManager?
    weak var bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager?

    private let appConfigProvider: IAppConfigProvider
    private let ethereumKitManager: EthereumKitManager
    private let binanceSmartChainKitManager: BinanceSmartChainKitManager
    private let binanceKitManager: BinanceKitManager

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EthereumKitManager, binanceSmartChainKitManager: BinanceSmartChainKitManager, binanceKitManager: BinanceKitManager) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
        self.binanceKitManager = binanceKitManager
    }

    func adapter(wallet: Wallet) -> IAdapter? {
        let derivation = derivationSettingsManager?.setting(coinType: wallet.coin.type)?.derivation
        let syncMode = initialSyncSettingsManager?.setting(coinType: wallet.coin.type, accountOrigin: wallet.account.origin)?.syncMode

        switch wallet.coin.type {
        case .bitcoin:
            return try? BitcoinAdapter(wallet: wallet, syncMode: syncMode, derivation: derivation, testMode: appConfigProvider.testMode)
        case .litecoin:
            return try? LitecoinAdapter(wallet: wallet, syncMode: syncMode, derivation: derivation, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            let bitcoinCashCoinType = bitcoinCashCoinTypeManager?.bitcoinCashCoinType
            return try? BitcoinCashAdapter(wallet: wallet, syncMode: syncMode, bitcoinCashCoinType: bitcoinCashCoinType, testMode: appConfigProvider.testMode)
        case .dash:
            return try? DashAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)
        case .zcash:
            return try? ZcashAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)
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
