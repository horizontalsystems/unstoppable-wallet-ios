import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarketViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketService
    public let categoriesService: MarketCategoriesService

    private let updateCategoryRelay = PublishRelay<()>()

    init(service: MarketService, categoriesService: MarketCategoriesService) {
        self.service = service
        self.categoriesService = categoriesService

        subscribe(disposeBag, categoriesService.currentCategoryChangedObservable) { [weak self] in self?.updateCategory() }
    }

    private func updateCategory() {
        updateCategoryRelay.accept(())
    }

}

extension MarketViewModel {

    var updateCategorySignal: Signal<()> {
        updateCategoryRelay.asSignal()
    }

    var currentCategoryIndex: Int {
        categoriesService.currentCategory.rawValue
    }

}
