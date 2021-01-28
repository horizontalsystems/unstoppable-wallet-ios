import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarketCategoriesViewModel {
    private let disposeBag = DisposeBag()
    private let service: MarketCategoriesService

    private var updateIndexRelay = PublishRelay<()>()

    init(service: MarketCategoriesService) {
        self.service = service

        subscribe(disposeBag, service.currentCategoryChangedObservable) { [weak self] in self?.syncCurrentCategory() }
    }

    private func syncCurrentCategory() {
        updateIndexRelay.accept(())
    }

}

extension MarketCategoriesViewModel {
    public var currentIndex: Int { service.currentCategory.rawValue }
    public var categories: [FilterHeaderView.ViewItem] { service.categories.map { FilterHeaderView.ViewItem.item(title: $0.title) } }

    public func didSelect(index: Int) {
        guard index < categories.count else {
            return
        }

        service.currentCategory = service.categories[index]
    }

    public var updateIndexSignal: Signal<()> {
        updateIndexRelay.asSignal()
    }

}

extension MarketModule.Category {

    var title: String {
        switch self {
        case .overview: return "market.category.overview".localized
        case .discovery: return "market.category.discovery".localized
        case .watchlist: return "market.category.watchlist".localized
        }
    }

}
