import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarketViewModel {
    private let disposeBag = DisposeBag()

    public let categoriesService: MarketCategoriesService

    private let updateCategoryRelay = PublishRelay<()>()

    init(categoriesService: MarketCategoriesService) {
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
        get {
            categoriesService.currentCategory.rawValue
        }
        set {
            guard let category = MarketModule.Category(rawValue: newValue) else {
                return
            }
            categoriesService.currentCategory = category
        }
    }

}
