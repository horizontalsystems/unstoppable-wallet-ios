import HSBitcoinKit
import HSEthereumKit

class AdapterFactory: IAdapterFactory {
    private let appConfigProvider: IAppConfigProvider
    private let localStorage: ILocalStorage

    init(appConfigProvider: IAppConfigProvider, localStorage: ILocalStorage) {
        self.appConfigProvider = appConfigProvider
        self.localStorage = localStorage
    }

    func adapter(forCoinType type: CoinType, authData: AuthData) -> IAdapter? {
        switch type {
        case .bitcoin:
            return BitcoinAdapter.bitcoinAdapter(authData: authData, newWallet: localStorage.isNewWallet, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            return BitcoinAdapter.bitcoinCashAdapter(authData: authData, newWallet: localStorage.isNewWallet, testMode: appConfigProvider.testMode)
        case .ethereum:
            return EthereumAdapter.ethereumAdapter(words: authData.words, testMode: appConfigProvider.testMode)
        case .erc20(_, _): return nil
        }
    }

}
