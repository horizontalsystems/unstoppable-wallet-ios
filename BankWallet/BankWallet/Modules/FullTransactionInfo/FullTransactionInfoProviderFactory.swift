class FullTransactionInfoProviderFactory {

    private let apiManager: IJSONApiManager
    private let dataProviderManager: IFullTransactionDataProviderManager

    init(apiManager: IJSONApiManager, dataProviderManager: IFullTransactionDataProviderManager) {
        self.apiManager = apiManager
        self.dataProviderManager = dataProviderManager
    }

}

extension FullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory {

    func provider(for coinCode: String) -> IFullTransactionInfoProvider {
        let providerName = dataProviderManager.baseProvider(for: coinCode).name

        var provider: IProvider
        let adapter: IFullTransactionInfoAdapter

        if coinCode.range(of: "BTC") != nil {
            let bitcoinProvider = dataProviderManager.bitcoin(for: providerName)
            provider = bitcoinProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinProvider, coinCode: coinCode)
        } else if coinCode.range(of: "BCH") != nil {
            let bitcoinCashProvider = dataProviderManager.bitcoinCash(for: providerName)
            provider = bitcoinCashProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinCashProvider, coinCode: coinCode)
        } else {
            let ethereumProvider = dataProviderManager.ethereum(for: providerName)
            provider = ethereumProvider
            adapter = EthereumTransactionInfoAdapter(provider: ethereumProvider, coinCode: coinCode)
        }
        return FullTransactionInfoProvider(apiManager: apiManager, adapter: adapter, provider: provider)
    }

}
