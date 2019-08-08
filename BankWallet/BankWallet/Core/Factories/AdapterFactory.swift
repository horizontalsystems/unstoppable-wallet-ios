class AdapterFactory: IAdapterFactory {
    private let appConfigProvider: IAppConfigProvider
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let binanceKitManager: BinanceKitManager

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EthereumKitManager, eosKitManager: EosKitManager, binanceKitManager: BinanceKitManager) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.eosKitManager = eosKitManager
        self.binanceKitManager = binanceKitManager
    }

    func adapter(wallet: Wallet) -> IAdapter? {
        switch wallet.coin.type {
        case .bitcoin:
            return try? BitcoinAdapter(wallet: wallet, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            return try? BitcoinCashAdapter(wallet: wallet, testMode: appConfigProvider.testMode)
        case .dash:
            return try? DashAdapter(wallet: wallet, testMode: appConfigProvider.testMode)
        case .ethereum:
            if let ethereumKit = try? ethereumKitManager.ethereumKit(account: wallet.account) {
                return EthereumAdapter(wallet: wallet, ethereumKit: ethereumKit)
            }
        case let .erc20(address, decimal, fee):
            if let ethereumKit = try? ethereumKitManager.ethereumKit(account: wallet.account) {
                return try? Erc20Adapter(wallet: wallet, ethereumKit: ethereumKit, contractAddress: address, decimal: decimal, fee: fee)
            }
        case let .eos(token, symbol):
            if let eosKit = try? eosKitManager.eosKit(account: wallet.account) {
                return EosAdapter(wallet: wallet, eosKit: eosKit, token: token, symbol: symbol)
            }
        case let .binance(symbol):
            if let binanceKit = try? binanceKitManager.binanceKit(account: wallet.account) {
                return BinanceAdapter(wallet: wallet, binanceKit: binanceKit, symbol: symbol)
            }
        }

        return nil
    }

}
