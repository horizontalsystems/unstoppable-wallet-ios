import RxSwift
import RxRelay
import RxCocoa

class MarketOverviewCategoryViewModel {
    private let service: MarketDiscoveryCategoryService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<CategoryViewItem>>(value: .loading)

    init(service: MarketDiscoveryCategoryService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketDiscoveryCategoryService.State) {
        let items: MarketDiscoveryCategoryService.DiscoveryItem
        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case .items(let items):
            stateRelay.accept(.completed(CategoryViewItem(viewItems: items.prefix(5).compactMap { viewItem(item: $0) })))
        case .failed(let error):
            stateRelay.accept(.failed(error))
        }
    }

    private func viewItem(item: MarketDiscoveryCategoryService.DiscoveryItem) -> ViewItem? {
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

extension MarketOverviewCategoryViewModel {

    var viewItem: CategoryViewItem? {
        stateRelay.value.data
    }

}

extension MarketOverviewCategoryViewModel: IMarketOverviewSectionViewModel {

    var stateObservable: Observable<DataStatus<()>> {
        stateRelay.map { $0.map { _ in () } }
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
