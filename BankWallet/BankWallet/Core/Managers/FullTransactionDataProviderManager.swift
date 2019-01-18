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
            HorSysEthereumProvider(testMode: false),
            EtherscanEthereumProvider(),
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

    func providers(for coinCode: String) -> [IProvider] {
        if coinCode.range(of: "BTC") != nil {
            return bitcoinProviders
        } else if coinCode.range(of: "BCH") != nil {
            return bitcoinCashProviders
        }
        return ethereumProviders
    }

    func baseProvider(for coinCode: String) -> IProvider {
        if coinCode.range(of: "ETH") != nil {
            let name = localStorage.baseEthereumProvider ?? ethereumProviders[0].name
            return ethereum(for: name)
        }
        let name = localStorage.baseBitcoinProvider ?? bitcoinProviders[0].name
        return bitcoin(for: name)
    }

    func setBaseProvider(name: String, for coinCode: String) {
        if coinCode.range(of: "ETH") != nil {
            localStorage.baseEthereumProvider = name
        } else {
            localStorage.baseBitcoinProvider = name
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
