import HSBitcoinKit
import HSEthereumKit

class AdapterFactory: IAdapterFactory {
    let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func adapter(forCoin coin: Coin, words: [String]) -> IAdapter? {
        switch coin.blockChain {
        case .bitcoin(let type):
            let network: BitcoinKit.Network = appConfigProvider.networkType == .main ? .mainNet : .testNet
            let coin: BitcoinKit.Coin = type == .bitcoin ? .bitcoin(network: network) : .bitcoinCash(network: network)
            return BitcoinAdapter(words: words, coin: coin)
        case .ethereum(let type):
            let network: EthereumKit.NetworkType = appConfigProvider.networkType == .main ? .mainNet : .testNet
            if case .ethereum = type {
                let coin: EthereumKit.Coin = .ethereum(network: network)
                return EthereumAdapter(words: words, coin: coin)
            }
        }
        return nil
    }

}
