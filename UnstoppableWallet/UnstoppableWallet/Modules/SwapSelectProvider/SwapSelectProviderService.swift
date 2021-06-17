import RxSwift
import RxRelay
import ThemeKit

class SwapSelectProviderService {
    private let dataSourceManager: SwapProviderManager

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(dataSourceManager: SwapProviderManager) {
        self.dataSourceManager = dataSourceManager

        syncItems()
    }

    private func syncItems() {
        guard let dex = dataSourceManager.dex else {
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

    func set(provider: SwapModuleNew.DexNew.Provider) {
        dataSourceManager.set(provider: provider)

        syncItems()
    }

}

extension SwapSelectProviderService {

    struct Item {
        let provider: SwapModuleNew.DexNew.Provider
        let selected: Bool
    }

}
