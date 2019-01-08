import HSBitcoinKit
import HSEthereumKit

class AdapterFactory: IAdapterFactory {
    let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func adapter(forCoinType type: CoinType, authData: AuthData) -> IAdapter? {
        switch type {
        case .bitcoin:
            return BitcoinAdapter.bitcoinAdapter(authData: authData, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            return BitcoinAdapter.bitcoinCashAdapter(authData: authData, testMode: appConfigProvider.testMode)
        case .ethereum:
            return EthereumAdapter.ethereumAdapter(words: authData.words, testMode: appConfigProvider.testMode)
        case .erc20(_, _): return nil
        }
    }

}
