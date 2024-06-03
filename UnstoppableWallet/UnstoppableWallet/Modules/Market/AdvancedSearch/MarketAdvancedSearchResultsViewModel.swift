import Combine
import Foundation
import MarketKit

class MarketAdvancedSearchResultsViewModel: ObservableObject {
    private let currencyManager = App.shared.currencyManager
    private var cancellables = Set<AnyCancellable>()

    private let internalMarketInfos: [MarketInfo]
    let timePeriod: HsTimePeriod

    @Published var marketInfos: [MarketInfo] = []

    var sortBy: MarketModule.SortBy = .highestCap {
        didSet {
            syncState()
        }
    }

    init(marketInfos: [MarketInfo], timePeriod: HsTimePeriod) {
        internalMarketInfos = marketInfos
        self.timePeriod = timePeriod

        syncState()
    }

    private func syncState() {
        marketInfos = internalMarketInfos.sorted(sortBy: sortBy, timePeriod: timePeriod)
    }
}

extension MarketAdvancedSearchResultsViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var sortBys: [MarketModule.SortBy] {
        [.highestCap, .lowestCap, .gainers, .losers]
    }
}
