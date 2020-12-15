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

extension MarketCategoriesService.Category {

    var title: String {
        switch self {
        case .all: return "market.category.all".localized
        case .favorites: return "market.category.favorites".localized
        }
    }

}
