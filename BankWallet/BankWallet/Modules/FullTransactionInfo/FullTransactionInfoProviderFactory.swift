class FullTransactionInfoProviderFactory {

    private let apiProvider: IJsonApiProvider
    private let dataProviderManager: IFullTransactionDataProviderManager

    init(apiProvider: IJsonApiProvider, dataProviderManager: IFullTransactionDataProviderManager) {
        self.apiProvider = apiProvider
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
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinProvider, coin: coin, unitName: "satoshi")
        } else if coin.type == .bitcoinCash {
            let bitcoinCashProvider = dataProviderManager.bitcoinCash(for: providerName)
            provider = bitcoinCashProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinCashProvider, coin: coin, unitName: "satoshi")
        } else if coin.type == .dash {
            let dashProvider = dataProviderManager.dash(for: providerName)
            provider = dashProvider
            adapter = BitcoinTransactionInfoAdapter(provider: dashProvider, coin: coin, unitName: "duff")
        } else if case .eos = coin.type {
            let eosProvider = dataProviderManager.eos(for: providerName)
            provider = eosProvider
            adapter = EosTransactionInfoAdapter(provider: eosProvider, coin: coin)
        } else {
            let ethereumProvider = dataProviderManager.ethereum(for: providerName)
            provider = ethereumProvider
            adapter = EthereumTransactionInfoAdapter(provider: ethereumProvider, coin: coin)
        }
        return FullTransactionInfoProvider(apiProvider: apiProvider, adapter: adapter, provider: provider)
    }

}
