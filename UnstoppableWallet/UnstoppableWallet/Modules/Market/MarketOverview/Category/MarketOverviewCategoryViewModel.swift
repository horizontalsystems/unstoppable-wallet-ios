import MarketKit
import RxCocoa
import RxRelay
import RxSwift
import UIKit

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
        var marketCap: String?
        if let amount = category.marketCap {
            marketCap = ValueFormatter.instance.formatShort(currency: service.currency, value: amount)
        } else {
            marketCap = "----"
        }

        let diff = category.diff(timePeriod: .day1)
        let diffString: String? = diff.flatMap {
            ValueFormatter.instance.format(percentValue: $0)
        }

        let diffType: DiffType = (diff?.isSignMinus ?? true) ? .down : .up

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

    var marketTop: MarketModule.MarketTop { service.marketTop }
    var listType: MarketOverviewTopCoinsService.ListType { service.listType }
}

extension MarketOverviewCategoryViewModel {
    struct ViewItem {
        let uid: String
        let imageUrl: String
        let name: String
        let marketCap: String?
        let diff: String?
        let diffType: DiffType
    }

    enum DiffType {
        case down
        case up

        var textColor: UIColor {
            switch self {
            case .up: return .themeRemus
            case .down: return .themeLucian
            }
        }
    }
}
