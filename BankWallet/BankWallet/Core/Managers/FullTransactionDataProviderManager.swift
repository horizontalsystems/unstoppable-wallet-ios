import RxSwift

class FullTransactionDataProviderManager {

    private var bitcoinProviders: [IBitcoinForksProvider] {
        appConfigProvider.testMode ? [
            HorSysBitcoinProvider(testMode: true)
        ] : [
            HorSysBitcoinProvider(testMode: false),
            BlockChairBitcoinProvider(),
//            BlockExplorerBitcoinProvider(),
            BtcComBitcoinProvider()
        ]
    }

    private var bitcoinCashProviders: [IBitcoinForksProvider] {
        appConfigProvider.testMode ? [
        ] : [
            CoinSpaceBitcoinCashProvider(),
            BlockChairBitcoinCashProvider(),
//            BlockExplorerBitcoinCashProvider(),
            BtcComBitcoinCashProvider()
        ]
    }

    private var ethereumProviders: [IEthereumForksProvider] {
        appConfigProvider.testMode ? [
//            HorSysEthereumProvider(testMode: true),
            EtherscanEthereumProvider(testMode: true)
        ] : [
            EtherscanEthereumProvider(testMode: false),
//            HorSysEthereumProvider(testMode: false),
            BlockChairEthereumProvider()
        ]
    }

    private var dashProviders: [IBitcoinForksProvider] {
        appConfigProvider.testMode ? [
            HorSysDashProvider(testMode: true),
        ] : [
            HorSysDashProvider(testMode: false),
            BlockChairDashProvider(),
            InsightDashProvider()
        ]
    }

    private var eosProviders: [IEosProvider] {
        [
//            EosInfraProvider(),
            EosGreymassProvider()
        ]
    }

    private var binanceProviders: [IBinanceProvider] {
        appConfigProvider.testMode ? [
            BinanceOrgProvider(testMode: true),
        ] : [
            BinanceOrgProvider(testMode: false)
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
        } else if coin.type == .dash {
            return dashProviders
        } else if case .binance = coin.type {
            return binanceProviders
        } else if case .eos = coin.type {
            return eosProviders
        }
        return ethereumProviders
    }

    func baseProvider(for coin: Coin) -> IProvider {
        if coin.type == .bitcoin {
            let name = localStorage.baseBitcoinProvider ?? bitcoinProviders[0].name
            return bitcoin(for: name)
        }
        if coin.type == .bitcoinCash {
            let name = localStorage.baseBitcoinCashProvider ?? bitcoinCashProviders[0].name
            return bitcoinCash(for: name)
        }
        if coin.type == .dash {
            let name = localStorage.baseDashProvider ?? dashProviders[0].name
            return dash(for: name)
        }
        if case .binance = coin.type {
            let name = localStorage.baseBinanceProvider ?? binanceProviders[0].name
            return dash(for: name)
        }
        if case .eos = coin.type {
            let name = localStorage.baseEosProvider ?? eosProviders[0].name
            return eos(for: name)
        }
        let name = localStorage.baseEthereumProvider ?? ethereumProviders[0].name
        return ethereum(for: name)
    }

    func setBaseProvider(name: String, for coin: Coin) {
        if coin.type == .bitcoin {
            localStorage.baseBitcoinProvider = name
        } else if coin.type == .bitcoinCash {
            localStorage.baseBitcoinCashProvider = name
        } else if coin.type == .dash {
            localStorage.baseDashProvider = name
        } else if case .binance = coin.type {
            localStorage.baseBinanceProvider = name
        } else if case .eos = coin.type {
            localStorage.baseEosProvider = name
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

    func dash(for name: String) -> IBitcoinForksProvider {
        let providers = dashProviders
        return providers.first(where: { provider in provider.name == name }) ?? providers[0]
    }

    func eos(for name: String) -> IEosProvider {
        let providers = eosProviders
        return providers.first(where: { provider in provider.name == name }) ?? providers[0]
    }

    func ethereum(for name: String) -> IEthereumForksProvider {
        let providers = ethereumProviders
        return providers.first(where: { provider in provider.name == name }) ?? providers[0]
    }

    func binance(for name: String) -> IBinanceProvider {
        let providers = binanceProviders
        return providers.first(where: { provider in provider.name == name }) ?? providers[0]
    }

}
