import RxSwift

class FullTransactionDataProviderManager {
    static var bitcoinProviders: [IBitcoinForksProvider] {
        return [HorSysBitcoinProvider(testMode: false),
                BlockChairBitcoinProvider(),
                BlockExplorerBitcoinProvider(),
                BtcComBitcoinProvider()
        ]
    }
    static var bitcoinCashProviders: [IBitcoinForksProvider] {
        return [HorSysBitcoinCashProvider(testMode: false),
                BlockChairBitcoinCashProvider(),
                BlockExplorerBitcoinCashProvider(),
                BtcComBitcoinCashProvider()
        ]
    }
    static var ethereumProviders: [IEthereumForksProvider] {
        return [HorSysEthereumProvider(testMode: false),
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
            return FullTransactionDataProviderManager.bitcoinProviders
        } else if coinCode.range(of: "BCH") != nil {
            return FullTransactionDataProviderManager.bitcoinCashProviders
        }
        return FullTransactionDataProviderManager.ethereumProviders
    }

    func baseProvider(for coinCode: String) -> IProvider {
        if coinCode.range(of: "ETH") != nil {
            let name = localStorage.baseEthereumProvider ?? FullTransactionDataProviderManager.ethereumProviders[0].name
            return ethereum(for: name)
        }
        let name = localStorage.baseBitcoinProvider ?? FullTransactionDataProviderManager.bitcoinProviders[0].name
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
        return FullTransactionDataProviderManager.bitcoinProviders.first(where: { provider in provider.name == name }) ?? HorSysBitcoinProvider(testMode: false)
    }

    func bitcoinCash(for name: String) -> IBitcoinForksProvider {
        return FullTransactionDataProviderManager.bitcoinCashProviders.first(where: { provider in provider.name == name }) ?? HorSysBitcoinCashProvider(testMode: false)
    }

    func ethereum(for name: String) -> IEthereumForksProvider {
        return FullTransactionDataProviderManager.ethereumProviders.first(where: { provider in provider.name == name }) ?? HorSysEthereumProvider(testMode: false)
    }

}
