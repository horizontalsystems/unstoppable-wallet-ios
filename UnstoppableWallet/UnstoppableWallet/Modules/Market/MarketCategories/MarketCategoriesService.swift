import Foundation
import RxSwift
import RxRelay

class MarketCategoriesService {
    private let disposeBag = DisposeBag()
    private let localStorage: ILocalStorage

    private var currentCategoryChangedRelay = PublishRelay<()>()

    public var currentCategory: MarketModule.Category {
        get {
            localStorage.marketCategory.flatMap { MarketModule.Category(rawValue: $0) } ?? categories[0]
        }
        set {
            localStorage.marketCategory = newValue.rawValue
            currentCategoryChangedRelay.accept(())
        }
    }

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension MarketCategoriesService {

    public var categories: [MarketModule.Category] {
        MarketModule.Category.allCases
    }

    public var currentCategoryChangedObservable: Observable<()> {
        currentCategoryChangedRelay.asObservable()
    }

}
