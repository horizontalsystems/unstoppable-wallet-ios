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

        subscribe(disposeBag, service.categoriesObservable) { [weak self] in self?.sync(categories: $0) }

        sync(categories: service.categories)
    }

    private func sync(categories: [CoinCategory]?) {
        viewItemsRelay.accept(categories.map { $0.map { viewItem(category: $0) } })
    }

    private func viewItem(category: CoinCategory) -> ViewItem {
        let (marketCap, diffString, diffType) = MarketDiscoveryModule.formatCategoryMarketData(category: category, timePeriod: .day1, currency: service.currency)

        return ViewItem(
                uid: category.uid,
                imageUrl: category.imageUrl,
                name: category.name,
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

    func category(uid: String) -> CoinCategory? {
        service.category(uid: uid)
    }

}

extension MarketOverviewCategoryViewModel {

    struct ViewItem {
        let uid: String
        let imageUrl: String
        let name: String
        let marketCap: String?
        let diff: String?
        let diffType: MarketDiscoveryModule.DiffType
    }

}
