import Combine
import Foundation
import MarketKit
import RxRelay
import RxSwift

class MarketOverviewCategoryService {
    private let baseService: MarketOverviewService
    private var cancellables = Set<AnyCancellable>()

    let marketTop: MarketModule.MarketTop = .top100
    let listType: MarketOverviewTopCoinsService.ListType

    private let categoriesRelay = PublishRelay<[CoinCategory]?>()
    private(set) var categories: [CoinCategory]? {
        didSet {
            categoriesRelay.accept(categories)
        }
    }

    init(listType: MarketOverviewTopCoinsService.ListType, baseService: MarketOverviewService) {
        self.listType = listType
        self.baseService = baseService

        baseService.$state
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

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
