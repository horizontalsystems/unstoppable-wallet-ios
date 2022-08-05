import RxSwift
import RxRelay
import ThemeKit
import MarketKit

class SwapSelectProviderService {
    private let dexManager: ISwapDexManager
    private let evmBlockchainManager: EvmBlockchainManager

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(dexManager: ISwapDexManager, evmBlockchainManager: EvmBlockchainManager) {
        self.dexManager = dexManager
        self.evmBlockchainManager = evmBlockchainManager

        syncItems()
    }

    private func syncItems() {
        guard let dex = dexManager.dex else {
            items = []
            return
        }
        var items = [Item]()


        for provider in dex.blockchainType.allowedProviders {
            items.append(Item(provider: provider, selected: provider == dex.provider))
        }

        self.items = items
    }

}

extension SwapSelectProviderService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var blockchain: Blockchain? {
        dexManager.dex.flatMap { evmBlockchainManager.blockchain(type: $0.blockchainType) }
    }

    func set(provider: SwapModule.Dex.Provider) {
        dexManager.set(provider: provider)

        syncItems()
    }

}

extension SwapSelectProviderService {

    struct Item {
        let provider: SwapModule.Dex.Provider
        let selected: Bool
    }

}
