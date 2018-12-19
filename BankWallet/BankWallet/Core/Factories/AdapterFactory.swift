import HSBitcoinKit
import HSEthereumKit

class AdapterFactory: IAdapterFactory {
    let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func adapter(forCoinType type: CoinType, words: [String]) -> IAdapter? {
        switch type {
        case .bitcoin:
            return BitcoinAdapter.bitcoinAdapter(words: words, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            return BitcoinAdapter.bitcoinCashAdapter(words: words, testMode: appConfigProvider.testMode)
        case .ethereum:
            return EthereumAdapter.ethereumAdapter(words: words, testMode: appConfigProvider.testMode)
        case .erc20(_, _): return nil
        }
    }

}
