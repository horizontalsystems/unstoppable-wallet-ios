import BitcoinCore

class AdapterFactory: IAdapterFactory {
    weak var derivationSettingsManager: IDerivationSettingsManager?
    weak var initialSyncSettingsManager: IInitialSyncSettingsManager?
    weak var bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager?

    private let appConfigProvider: IAppConfigProvider
    private let ethereumKitManager: EthereumKitManager
    private let binanceKitManager: BinanceKitManager

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EthereumKitManager, binanceKitManager: BinanceKitManager) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
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
            if let ethereumKit = try? ethereumKitManager.ethereumKit(account: wallet.account) {
                return EthereumAdapter(ethereumKit: ethereumKit)
            }
        case let .erc20(address):
            if let ethereumKit = try? ethereumKitManager.ethereumKit(account: wallet.account) {
                let smartContractFee = appConfigProvider.smartContractFees[wallet.coin.type] ?? 0
                let minimumBalance = appConfigProvider.minimumBalances[wallet.coin.type] ?? 0
                let minimumSpendableAmount = appConfigProvider.minimumSpendableAmounts[wallet.coin.type]

                return try? Erc20Adapter(
                        ethereumKit: ethereumKit, contractAddress: address, decimal: wallet.coin.decimal,
                        fee: smartContractFee, minimumRequiredBalance: minimumBalance, minimumSpendableAmount: minimumSpendableAmount
                )
            }
        case let .binance(symbol):
            if let binanceKit = try? binanceKitManager.binanceKit(account: wallet.account) {
                return BinanceAdapter(binanceKit: binanceKit, symbol: symbol)
            }
        }

        return nil
    }

}
