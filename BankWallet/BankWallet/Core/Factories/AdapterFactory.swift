import HSBitcoinKit
import HSEthereumKit
import RxSwift

class AdapterFactory: IAdapterFactory {
    private let appConfigProvider: IAppConfigProvider
    private let localStorage: ILocalStorage
    private let ethereumKitManager: IEthereumKitManager

    init(appConfigProvider: IAppConfigProvider, localStorage: ILocalStorage, ethereumKitManager: IEthereumKitManager) {
        self.appConfigProvider = appConfigProvider
        self.localStorage = localStorage
        self.ethereumKitManager = ethereumKitManager
    }

    func adapter(forCoin coin: Coin, authData: AuthData) -> IAdapter? {
        switch coin.type {
        case .bitcoin, .bitcoinCash:
            return BitcoinAdapter(coin: coin, authData: authData, newWallet: localStorage.isNewWallet, testMode: appConfigProvider.testMode)
        case .ethereum:
            let ethereumKit = ethereumKitManager.ethereumKit(authData: authData)
            return EthereumAdapter(coin: coin, ethereumKit: ethereumKit)
        case let .erc20(address, decimal):
            let ethereumKit = ethereumKitManager.ethereumKit(authData: authData)
            return Erc20Adapter(coin: coin, ethereumKit: ethereumKit, contractAddress: address, decimal: decimal)
        }
    }

}
