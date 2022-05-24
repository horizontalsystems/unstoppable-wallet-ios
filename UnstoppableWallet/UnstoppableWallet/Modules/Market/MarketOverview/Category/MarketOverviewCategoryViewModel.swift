import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewCategoryViewModel {
    private let service: MarketOverviewCategoryService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)

    init(service: MarketOverviewCategoryService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [MarketDiscoveryCategoryService.Item]?) {
        viewItemsRelay.accept(items.map { $0.map { viewItem(item: $0) } })
    }

    private func viewItem(item: MarketDiscoveryCategoryService.Item) -> ViewItem {
        let (marketCap, diffString, diffType) = MarketDiscoveryModule.formatCategoryMarketData(category: item, currency: service.currency)

        return ViewItem(
                category: item.category,
                uid: item.uid,
                imageUrl: item.imageUrl,
                name: item.name,
                marketCap: marketCap,
                diff: diffString,
                diffType: diffType
        )
    }

}

extension MarketOverviewCategoryViewModel {

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

}

extension MarketOverviewCategoryViewModel {

    struct ViewItem {
        let category: CoinCategory
        let uid: String
        let imageUrl: String
        let name: String
        let marketCap: String?
        let diff: String?
        let diffType: MarketDiscoveryModule.DiffType
    }

}
