import Foundation
import RxSwift
import RxRelay

class MarketCategoriesService {
    private let disposeBag = DisposeBag()
    private let localStorage: ILocalStorage

    private var currentCategoryChangedRelay = PublishRelay<()>()
    public var currentCategory: Category = .all {
        didSet {
            if currentCategory != oldValue {
                localStorage.defaultMarketCategory = currentCategory.rawValue
                currentCategoryChangedRelay.accept(())
            }
        }
    }

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage

        currentCategory = savedCategory
    }

    private var savedCategory: Category {
        localStorage.defaultMarketCategory.flatMap { Category(rawValue: $0) } ?? Category.all
    }

}

extension MarketCategoriesService {

    public var categories: [Category] {
        [.all, .defi]
    }

    public var currentCategoryChangedObservable: Observable<()> {
        currentCategoryChangedRelay.asObservable()
    }

}

extension MarketCategoriesService {

    public enum Category: Int {
        case all
        case defi
//        case favorites
    }

}
