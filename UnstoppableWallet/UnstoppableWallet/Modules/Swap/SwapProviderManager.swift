import UIKit
import CoinKit
import SectionsTableView
import RxSwift
import RxCocoa
import UniswapKit
import OneInchKit

class SwapProviderManager {
    private let localStorage: ILocalStorage

    private let dataSourceProviderUpdatedRelay = PublishRelay<()>()
    private(set) var dataSourceProvider: ISwapProvider? {
        didSet {
            dataSourceProviderUpdatedRelay.accept(())
        }
    }

    var dex: SwapModuleNew.DexNew?

    init(localStorage: ILocalStorage, coinFrom: Coin?) {
        self.localStorage = localStorage

        initSectionsDataSource(coinFrom: coinFrom)
    }

    private func initSectionsDataSource(coinFrom: Coin?) {
        let blockchain: SwapModuleNew.DexNew.Blockchain?
        switch coinFrom?.type {
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

        if dex?.blockchain == blockchain {
            return
        }

        guard let blockchain = blockchain else {
            dex = nil
            dataSourceProvider = nil
            return
        }

        let dexProvider = localStorage.defaultProvider(blockchain: blockchain)
        let dex = SwapModuleNew.DexNew(blockchain: blockchain, provider: dexProvider)
        self.dex = dex

        dataSourceProvider = provider(dex: dex, coinFrom: coinFrom)
    }

    private func provider(dex: SwapModuleNew.DexNew, coinFrom: Coin? = nil) -> ISwapProvider? {
        let state = dataSourceProvider?.swapState ?? SwapModuleNew.DataSourceState(coinFrom: coinFrom)

        switch dex.provider {
        case .uniswap, .pancake:
            return UniswapModule(dex: dex, dataSourceState: state)
        case .oneInch:
            return OneInchModule(dex: dex, dataSourceState: state)
        }
    }

}

extension SwapProviderManager {

    func set(provider: SwapModuleNew.DexNew.Provider) {
        let dex: SwapModuleNew.DexNew
        if let oldDex = self.dex {
            oldDex.provider = provider
            dex = oldDex
        } else {
            let blockchain = provider.allowedBlockchains[0]
            dex = SwapModuleNew.DexNew(blockchain: blockchain, provider: provider)
        }

        self.dex = dex
        localStorage.setDefaultProvider(blockchain: dex.blockchain, provider: dex.provider)

        dataSourceProvider = self.provider(dex: dex)
    }

    var dataSourceUpdated: Observable<()> {
        dataSourceProviderUpdatedRelay.asObservable()
    }

}
