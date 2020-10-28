import HsToolKit

class FullTransactionInfoProviderFactory {
    private let networkManager: NetworkManager
    private let dataProviderManager: IFullTransactionDataProviderManager

    init(networkManager: NetworkManager, dataProviderManager: IFullTransactionDataProviderManager) {
        self.networkManager = networkManager
        self.dataProviderManager = dataProviderManager
    }

}

extension FullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory {

    func provider(for wallet: Wallet) -> IFullTransactionInfoProvider {
        let coin = wallet.coin
        let providerName = dataProviderManager.baseProvider(for: coin).name

        var provider: IProvider
        let adapter: IFullTransactionInfoAdapter

        if coin.type == .bitcoin {
            let bitcoinProvider = dataProviderManager.bitcoin(for: providerName)
            provider = bitcoinProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinProvider, coin: coin, unitName: "satoshi")
        } else if coin.type == .litecoin {
            let litecoinProvider = dataProviderManager.litecoin(for: providerName)
            provider = litecoinProvider
            adapter = BitcoinTransactionInfoAdapter(provider: litecoinProvider, coin: coin, unitName: "satoshi")
        } else if coin.type == .bitcoinCash {
            let bitcoinCashProvider = dataProviderManager.bitcoinCash(for: providerName)
            provider = bitcoinCashProvider
            adapter = BitcoinTransactionInfoAdapter(provider: bitcoinCashProvider, coin: coin, unitName: "satoshi")
        } else if coin.type == .dash {
            let dashProvider = dataProviderManager.dash(for: providerName)
            provider = dashProvider
            adapter = BitcoinTransactionInfoAdapter(provider: dashProvider, coin: coin, unitName: "duff")
        } else if case .binance = coin.type {
            let binanceProvider = dataProviderManager.binance(for: providerName)
            provider = binanceProvider
            adapter = BinanceTransactionInfoAdapter(provider: binanceProvider, feeCoinProvider: App.shared.feeCoinProvider, coin: coin)
        } else if case .zcash = coin.type {
            let zcashProvider = dataProviderManager.zcash(for: providerName)
            provider = zcashProvider
            adapter = ZcashTransactionInfoAdapter(provider: zcashProvider, feeCoinProvider: App.shared.feeCoinProvider, coin: coin)
        } else if case .eos = coin.type {
            let eosProvider = dataProviderManager.eos(for: providerName)
            provider = eosProvider
            adapter = EosTransactionInfoAdapter(provider: eosProvider, wallet: wallet)
        } else {
            let ethereumProvider = dataProviderManager.ethereum(for: providerName)
            provider = ethereumProvider
            adapter = EthereumTransactionInfoAdapter(provider: ethereumProvider, feeCoinProvider: App.shared.feeCoinProvider, coin: coin)
        }

        return FullTransactionInfoProvider(networkManager: networkManager, adapter: adapter, provider: provider)
    }

}
