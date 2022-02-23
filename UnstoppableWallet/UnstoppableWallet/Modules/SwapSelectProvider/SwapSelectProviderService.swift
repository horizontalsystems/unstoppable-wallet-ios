import RxSwift
import RxRelay
import ThemeKit

class SwapSelectProviderService {
    private let dexManager: ISwapDexManager

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(dexManager: ISwapDexManager) {
        self.dexManager = dexManager

        syncItems()
    }

    private func syncItems() {
        guard let dex = dexManager.dex else {
            items = []
            return
        }
        var items = [Item]()


        for provider in dex.blockchain.allowedProviders {
            items.append(Item(provider: provider, selected: provider == dex.provider))
        }

        self.items = items
    }

}

extension SwapSelectProviderService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var blockchain: EvmBlockchain? {
        dexManager.dex?.blockchain
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
