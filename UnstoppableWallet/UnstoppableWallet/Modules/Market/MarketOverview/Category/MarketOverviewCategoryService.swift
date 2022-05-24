import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewCategoryService {
    private let baseService: MarketOverviewService
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[MarketDiscoveryCategoryService.Item]?>()
    private(set) var items: [MarketDiscoveryCategoryService.Item]? {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(baseService: MarketOverviewService) {
        self.baseService = baseService

        subscribe(disposeBag, baseService.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync()
    }

    private func sync(state: DataStatus<MarketOverviewService.Item>? = nil) {
        let state = state ?? baseService.state

        items = state.data.map { item in
            item.marketOverview.coinCategories.map { MarketDiscoveryCategoryService.Item(category: $0, timePeriod: .day1) }
        }
    }

}

extension MarketOverviewCategoryService {

    var itemsObservable: Observable<[MarketDiscoveryCategoryService.Item]?> {
        itemsRelay.asObservable()
    }

    var currency: Currency {
        baseService.currency
    }

}
