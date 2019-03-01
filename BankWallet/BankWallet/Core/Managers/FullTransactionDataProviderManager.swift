import RxSwift

class FullTransactionDataProviderManager {
    private var bitcoinProviders: [IBitcoinForksProvider] {
        return appConfigProvider.testMode ? [HorSysBitcoinProvider(testMode: true)] : [
            HorSysBitcoinProvider(testMode: false),
            BlockChairBitcoinProvider(),
            BlockExplorerBitcoinProvider(),
            BtcComBitcoinProvider()
        ]
    }
    private var bitcoinCashProviders: [IBitcoinForksProvider] {
        return appConfigProvider.testMode ? [HorSysBitcoinCashProvider(testMode: true)] : [
            HorSysBitcoinCashProvider(testMode: false),
            BlockChairBitcoinCashProvider(),
            BlockExplorerBitcoinCashProvider(),
            BtcComBitcoinCashProvider()
        ]
    }
    private var ethereumProviders: [IEthereumForksProvider] {
        return appConfigProvider.testMode ? [HorSysEthereumProvider(testMode: true)] : [
            EtherscanEthereumProvider(),
            HorSysEthereumProvider(testMode: false),
            BlockChairEthereumProvider()
        ]
    }

    private let localStorage: ILocalStorage
    private let appConfigProvider: IAppConfigProvider

    let dataProviderUpdatedSignal = Signal()

    init(localStorage: ILocalStorage, appConfigProvider: IAppConfigProvider) {
        self.localStorage = localStorage
        self.appConfigProvider = appConfigProvider
    }

}

extension FullTransactionDataProviderManager: IFullTransactionDataProviderManager {

    func providers(for coin: Coin) -> [IProvider] {
        if coin.type == .bitcoin {
            return bitcoinProviders
        } else if coin.type == .bitcoinCash {
            return bitcoinCashProviders
        }
        return ethereumProviders
    }

    func baseProvider(for coin: Coin) -> IProvider {
        if coin.type == .bitcoin || coin.type == .bitcoinCash {
            let name = localStorage.baseBitcoinProvider ?? bitcoinProviders[0].name
            return bitcoin(for: name)
        }
        let name = localStorage.baseEthereumProvider ?? ethereumProviders[0].name
        return ethereum(for: name)
    }

    func setBaseProvider(name: String, for coin: Coin) {
        if coin.type == .bitcoin || coin.type == .bitcoinCash {
            localStorage.baseBitcoinProvider = name
        } else {
            localStorage.baseEthereumProvider = name
        }

        dataProviderUpdatedSignal.notify()
    }

    func bitcoin(for name: String) -> IBitcoinForksProvider {
        let providers = bitcoinProviders
        return providers.first(where: { provider in provider.name == name }) ?? providers[0]
    }

    func bitcoinCash(for name: String) -> IBitcoinForksProvider {
        let providers = bitcoinCashProviders
        return providers.first(where: { provider in provider.name == name }) ?? providers[0]
    }

    func ethereum(for name: String) -> IEthereumForksProvider {
        let providers = ethereumProviders
        return providers.first(where: { provider in provider.name == name }) ?? providers[0]
    }

}
