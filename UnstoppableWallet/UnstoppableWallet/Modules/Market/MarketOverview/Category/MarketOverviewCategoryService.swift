import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewCategoryService {
    private let baseService: MarketOverviewService
    private let disposeBag = DisposeBag()

    private let categoriesRelay = PublishRelay<[CoinCategory]?>()
    private(set) var categories: [CoinCategory]? {
        didSet {
            categoriesRelay.accept(categories)
        }
    }

    init(baseService: MarketOverviewService) {
        self.baseService = baseService

        subscribe(disposeBag, baseService.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync()
    }

    private func sync(state: DataStatus<MarketOverviewService.Item>? = nil) {
        let state = state ?? baseService.state

        categories = state.data.map { item in
            item.marketOverview.coinCategories
        }
    }

}

extension MarketOverviewCategoryService {

    var categoriesObservable: Observable<[CoinCategory]?> {
        categoriesRelay.asObservable()
    }

    var currency: Currency {
        baseService.currency
    }

    func category(uid: String) -> CoinCategory? {
        categories?.first { $0.uid == uid }
    }

}
