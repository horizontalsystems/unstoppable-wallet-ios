import RxSwift
import RxRelay
import RxCocoa

class MarketOverviewCategoryViewModel {
    private let service: MarketDiscoveryService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<()>>(value: .loading)

    var viewItem: CategoryViewItem?

    init(service: MarketDiscoveryService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketDiscoveryService.State) {
        if case let .discovery(items) = state {
            viewItem = CategoryViewItem(viewItems: items.prefix(5).compactMap {
                viewItem(item: $0)
            })

            stateRelay.accept(.completed(()))
        }
    }

    private func viewItem(item: MarketDiscoveryService.DiscoveryItem) -> ViewItem? {
        if case let .category(category) = item {
            let (marketCap, diffString, diffType) = MarketDiscoveryModule.formatCategoryMarketData(category: category, currency: service.currency)

            return ViewItem(
                    uid: category.uid,
                    imageUrl: category.imageUrl,
                    name: category.name,
                    marketCap: marketCap,
                    diff: diffString,
                    diffType: diffType
            )
        }

        return nil
    }

}

extension MarketOverviewCategoryViewModel: IMarketOverviewSectionViewModel {

    var stateDriver: Driver<DataStatus<()>> {
        stateRelay.asDriver()
    }

    func refresh() {
    }

}

extension MarketOverviewCategoryViewModel {

    struct CategoryViewItem {
        let title = "market.top.section.header.top_sectors".localized
        let imageName = "categories_20"
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let uid: String
        let imageUrl: String
        let name: String
        let marketCap: String?
        let diff: String?
        let diffType: MarketDiscoveryModule.DiffType
    }

}
