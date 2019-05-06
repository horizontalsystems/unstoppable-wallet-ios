class AdapterFactory: IAdapterFactory {
    private let appConfigProvider: IAppConfigProvider
    private let localStorage: ILocalStorage
    private let ethereumKitManager: IEthereumKitManager
    private let feeRateProvider: IFeeRateProvider

    init(appConfigProvider: IAppConfigProvider, localStorage: ILocalStorage, ethereumKitManager: IEthereumKitManager, feeRateProvider: IFeeRateProvider) {
        self.appConfigProvider = appConfigProvider
        self.localStorage = localStorage
        self.ethereumKitManager = ethereumKitManager
        self.feeRateProvider = feeRateProvider
    }

    func adapter(forCoin coin: Coin, authData: AuthData) -> IAdapter? {
        switch coin.type {
        case .bitcoin:
            let addressParser = AddressParser(validScheme: "bitcoin", removeScheme: true)
            return try? BitcoinAdapter(coin: coin, authData: authData, newWallet: localStorage.isNewWallet, addressParser: addressParser, feeRateProvider: feeRateProvider, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            let addressParser = AddressParser(validScheme: "bitcoincash", removeScheme: false)
            return try? BitcoinCashAdapter(coin: coin, authData: authData, newWallet: localStorage.isNewWallet, addressParser: addressParser, feeRateProvider: feeRateProvider, testMode: appConfigProvider.testMode)
        case .dash:
            let addressParser = AddressParser(validScheme: "dash", removeScheme: true)
            return try? DashAdapter(coin: coin, authData: authData, newWallet: localStorage.isNewWallet, addressParser: addressParser, feeRateProvider: feeRateProvider, testMode: appConfigProvider.testMode)
        case .ethereum:
            let addressParser = AddressParser(validScheme: "ethereum", removeScheme: true)
            if let ethereumKit = try? ethereumKitManager.ethereumKit(authData: authData) {
                return EthereumAdapter(coin: coin, ethereumKit: ethereumKit, addressParser: addressParser, feeRateProvider: feeRateProvider)
            }
        case let .erc20(address, decimal, fee):
            let addressParser = AddressParser(validScheme: "ethereum", removeScheme: true)
            if let ethereumKit = try? ethereumKitManager.ethereumKit(authData: authData) {
                return try? Erc20Adapter(coin: coin, ethereumKit: ethereumKit, contractAddress: address, decimal: decimal, fee: fee, addressParser: addressParser, feeRateProvider: feeRateProvider)
            }
        }

        return nil
    }

}
