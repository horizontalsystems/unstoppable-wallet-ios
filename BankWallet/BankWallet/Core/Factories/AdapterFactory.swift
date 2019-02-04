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

    func adapter(forCoinType type: CoinType, authData: AuthData) -> IAdapter? {
        switch type {
        case .bitcoin:
            return BitcoinAdapter.bitcoinAdapter(authData: authData, newWallet: localStorage.isNewWallet, testMode: appConfigProvider.testMode)
        case .bitcoinCash:
            return BitcoinAdapter.bitcoinCashAdapter(authData: authData, newWallet: localStorage.isNewWallet, testMode: appConfigProvider.testMode)
        case .ethereum:
            let ethereumKit = ethereumKitManager.ethereumKit(authData: authData)
            return EthereumAdapter.ethereumAdapter(ethereumKit: ethereumKit)
        case let .erc20(address, decimal):
            let ethereumKit = ethereumKitManager.ethereumKit(authData: authData)
            return Erc20Adapter.adapter(ethereumKit: ethereumKit, contractAddress: address, decimal: decimal)
        }
    }

}
