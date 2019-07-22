class AdapterFactory: IAdapterFactory {
    private let appConfigProvider: IAppConfigProvider
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let feeRateProvider: IFeeRateProvider

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EthereumKitManager, eosKitManager: EosKitManager, feeRateProvider: IFeeRateProvider) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.eosKitManager = eosKitManager
        self.feeRateProvider = feeRateProvider
    }

    func adapter(wallet: Wallet) -> IAdapter? {
        switch wallet.coin.type {
        case .bitcoin:
            let addressParser = AddressParser(validScheme: "bitcoin", removeScheme: true)
            return try? BitcoinAdapter(wallet: wallet, addressParser: addressParser, feeRateProvider: feeRateProvider, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            let addressParser = AddressParser(validScheme: "bitcoincash", removeScheme: false)
            return try? BitcoinCashAdapter(wallet: wallet, addressParser: addressParser, feeRateProvider: feeRateProvider, testMode: appConfigProvider.testMode)
        case .dash:
            let addressParser = AddressParser(validScheme: "dash", removeScheme: true)
            return try? DashAdapter(wallet: wallet, addressParser: addressParser, feeRateProvider: feeRateProvider, testMode: appConfigProvider.testMode)
        case .ethereum:
            let addressParser = AddressParser(validScheme: "ethereum", removeScheme: true)
            if let ethereumKit = try? ethereumKitManager.ethereumKit(account: wallet.account) {
                return EthereumAdapter(wallet: wallet, ethereumKit: ethereumKit, addressParser: addressParser, feeRateProvider: feeRateProvider)
            }
        case let .erc20(address, decimal, fee):
            let addressParser = AddressParser(validScheme: "ethereum", removeScheme: true)
            if let ethereumKit = try? ethereumKitManager.ethereumKit(account: wallet.account) {
                return try? Erc20Adapter(wallet: wallet, ethereumKit: ethereumKit, contractAddress: address, decimal: decimal, fee: fee, addressParser: addressParser, feeRateProvider: feeRateProvider)
            }
        case let .eos(token, symbol):
            if let eosKit = try? eosKitManager.eosKit(account: wallet.account) {
                return EosAdapter(wallet: wallet, eosKit: eosKit, token: token, symbol: symbol)
            }
        }

        return nil
    }

}
