import UIKit
import MarketKit
import SectionsTableView
import RxSwift
import RxCocoa
import UniswapKit
import OneInchKit

class SwapProviderManager {
    private let localStorage: LocalStorage
    private let evmBlockchainManager: EvmBlockchainManager

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

    init(localStorage: LocalStorage, evmBlockchainManager: EvmBlockchainManager, tokenFrom: MarketKit.Token?) {
        self.localStorage = localStorage
        self.evmBlockchainManager = evmBlockchainManager

        initSectionsDataSource(tokenFrom: tokenFrom)
    }

    private func initSectionsDataSource(tokenFrom: MarketKit.Token?) {
        let blockchainType: BlockchainType

        if let tokenFrom = tokenFrom {
            if let type = evmBlockchainManager.blockchain(token: tokenFrom)?.type {
                blockchainType = type
            } else {
                return
            }
        } else {
            blockchainType = .ethereum
        }

        let dexProvider = localStorage.defaultProvider(blockchainType: blockchainType)
        let dex = SwapModule.Dex(blockchainType: blockchainType, provider: dexProvider)

        dataSourceProvider = provider(dex: dex, tokenFrom: tokenFrom)
        self.dex = dex
    }

    private func provider(dex: SwapModule.Dex, tokenFrom: MarketKit.Token? = nil) -> ISwapProvider? {
        let state = dataSourceProvider?.swapState ?? SwapModule.DataSourceState(tokenFrom: tokenFrom)

        switch dex.provider {
        case .uniswap, .pancake, .quickSwap:
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
            let blockchainType = provider.allowedBlockchainTypes[0]
            dex = SwapModule.Dex(blockchainType: blockchainType, provider: provider)
        }

        self.dex = dex
        localStorage.setDefaultProvider(blockchainType: dex.blockchainType, provider: dex.provider)

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
