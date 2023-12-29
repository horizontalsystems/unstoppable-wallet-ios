import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketOverviewTopPairsService {
    private let baseService: MarketOverviewService
    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var marketPairs: [MarketPair]?

    init(baseService: MarketOverviewService) {
        self.baseService = baseService

        baseService.$state
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        sync(state: baseService.state)
    }

    private func sync(state: DataStatus<MarketOverviewService.Item>) {
        marketPairs = state.data.map { item in
            item.marketOverview.topPairs
        }
    }
}

extension MarketOverviewTopPairsService: IMarketListMarketPairDecoratorService {
    var currency: Currency {
        baseService.currency
    }
}
