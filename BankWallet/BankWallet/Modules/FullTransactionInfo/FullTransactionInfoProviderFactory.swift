class FullTransactionInfoProviderFactory {

    private let apiManager: IJSONApiManager
    private let appConfigProvider: IAppConfigProvider
    private let dataProviderManager: IFullTransactionDataProviderManager
    private let localStorage: ILocalStorage

    init(apiManager: IJSONApiManager, appConfigProvider: IAppConfigProvider, dataProviderManager: IFullTransactionDataProviderManager, localStorage: ILocalStorage) {
        self.apiManager = apiManager
        self.localStorage = localStorage
        self.dataProviderManager = dataProviderManager
        self.appConfigProvider = appConfigProvider
    }

}

extension FullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory {

    func provider(for coinCode: String) -> IFullTransactionInfoProvider {
        let providerName = dataProviderManager.baseProvider(for: coinCode).name

        var provider: IProvider
        let adapter: IFullTransactionInfoAdapter

        if coinCode.range(of: "BTC") != nil {
            let bitcoinProvider = appConfigProvider.testMode ? HorSysBitcoinProvider(testMode: true) : dataProviderManager.bitcoin(for: providerName)
            provider = bitcoinProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinProvider, coinCode: coinCode)
        } else if coinCode.range(of: "BCH") != nil {
            let bitcoinCashProvider = appConfigProvider.testMode ? HorSysBitcoinCashProvider(testMode: true) : dataProviderManager.bitcoinCash(for: providerName)
            provider = bitcoinCashProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinCashProvider, coinCode: coinCode)
        } else {
            let ethereumProvider = appConfigProvider.testMode ? HorSysEthereumProvider(testMode: true) : dataProviderManager.ethereum(for: providerName)
            provider = ethereumProvider
            adapter = EthereumTransactionInfoAdapter(provider: ethereumProvider, coinCode: coinCode)
        }
        return FullTransactionInfoProvider(apiManager: apiManager, adapter: adapter, provider: provider)
    }

}
