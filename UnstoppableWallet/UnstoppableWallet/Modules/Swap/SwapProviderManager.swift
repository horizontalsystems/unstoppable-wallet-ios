import UIKit
import MarketKit
import SectionsTableView
import RxSwift
import RxCocoa
import UniswapKit
import OneInchKit

class SwapProviderManager {
    private let localStorage: ILocalStorage

    private let dataSourceUpdatedRelay = PublishRelay<()>()
    private(set) var dataSourceProvider: ISwapProvider? {
        didSet {
            dataSourceUpdatedRelay.accept(())
        }
    }

    private let dexUpdatedRelay = PublishRelay<()>()
    var dex: SwapModule.Dex? {
        didSet {
            dexUpdatedRelay.accept(())
        }
    }

    init(localStorage: ILocalStorage, platformCoinFrom: PlatformCoin?) {
        self.localStorage = localStorage

        initSectionsDataSource(platformCoinFrom: platformCoinFrom)
    }

    private func initSectionsDataSource(platformCoinFrom: PlatformCoin?) {
        let blockchain: SwapModule.Dex.Blockchain?
        switch platformCoinFrom?.coinType {
        case .ethereum, .erc20:
            blockchain = .ethereum
        case .binanceSmartChain, .bep20:
            blockchain = .binanceSmartChain
        case nil:
            blockchain = .ethereum
        default:
            blockchain = nil
            return
        }

        guard let blockchain = blockchain else {
            dex = nil
            dataSourceProvider = nil
            return
        }

        let dexProvider = localStorage.defaultProvider(blockchain: blockchain)
        let dex = SwapModule.Dex(blockchain: blockchain, provider: dexProvider)

        dataSourceProvider = provider(dex: dex, platformCoinFrom: platformCoinFrom)
        self.dex = dex
    }

    private func provider(dex: SwapModule.Dex, platformCoinFrom: PlatformCoin? = nil) -> ISwapProvider? {
        let state = dataSourceProvider?.swapState ?? SwapModule.DataSourceState(platformCoinFrom: platformCoinFrom)

        switch dex.provider {
        case .uniswap, .pancake:
            return UniswapModule(dex: dex, dataSourceState: state)
        case .oneInch:
            return OneInchModule(dex: dex, dataSourceState: state)
        }
    }

}

extension SwapProviderManager: ISwapDexManager {

    func set(provider: SwapModule.Dex.Provider) {
        guard provider != dex?.provider else {
            return
        }

        let dex: SwapModule.Dex
        if let oldDex = self.dex {
            oldDex.provider = provider
            dex = oldDex
        } else {
            let blockchain = provider.allowedBlockchains[0]
            dex = SwapModule.Dex(blockchain: blockchain, provider: provider)
        }

        self.dex = dex
        localStorage.setDefaultProvider(blockchain: dex.blockchain, provider: dex.provider)

        dataSourceProvider = self.provider(dex: dex)
    }

    var dexUpdated: Signal<()> {
        dexUpdatedRelay.asSignal()
    }

}

extension SwapProviderManager: ISwapDataSourceManager {

    var dataSource: ISwapDataSource? {
        dataSourceProvider?.dataSource
    }

    var settingsDataSource: ISwapSettingsDataSource? {
        dataSourceProvider?.settingsDataSource
    }

    var dataSourceUpdated: Signal<()> {
        dataSourceUpdatedRelay.asSignal()
    }

}
