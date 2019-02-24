class FullTransactionInfoProviderFactory {

    private let apiManager: IJSONApiManager
    private let dataProviderManager: IFullTransactionDataProviderManager

    init(apiManager: IJSONApiManager, dataProviderManager: IFullTransactionDataProviderManager) {
        self.apiManager = apiManager
        self.dataProviderManager = dataProviderManager
    }

}

extension FullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory {

    func provider(for coin: Coin) -> IFullTransactionInfoProvider {
        let providerName = dataProviderManager.baseProvider(for: coin).name

        var provider: IProvider
        let adapter: IFullTransactionInfoAdapter

        if coin.type == .bitcoin {
            let bitcoinProvider = dataProviderManager.bitcoin(for: providerName)
            provider = bitcoinProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinProvider, coin: coin)
        } else if coin.type == .bitcoinCash {
            let bitcoinCashProvider = dataProviderManager.bitcoinCash(for: providerName)
            provider = bitcoinCashProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinCashProvider, coin: coin)
        } else {
            let ethereumProvider = dataProviderManager.ethereum(for: providerName)
            provider = ethereumProvider
            adapter = EthereumTransactionInfoAdapter(provider: ethereumProvider, coin: coin)
        }
        return FullTransactionInfoProvider(apiManager: apiManager, adapter: adapter, provider: provider)
    }

}
