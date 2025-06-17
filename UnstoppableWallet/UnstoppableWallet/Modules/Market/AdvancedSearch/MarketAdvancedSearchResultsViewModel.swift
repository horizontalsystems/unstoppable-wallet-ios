import Combine
import Foundation
import MarketKit

class MarketAdvancedSearchResultsViewModel: ObservableObject {
    private let currencyManager = Core.shared.currencyManager
    private let purchaseManager = Core.shared.purchaseManager
    private let watchlistManager = Core.shared.watchlistManager
    private var cancellables = Set<AnyCancellable>()

    private let internalMarketInfos: [MarketInfo]
    let timePeriod: HsTimePeriod

    @Published private(set) var premiumEnabled: Bool = false
    @Published var marketInfos: [MarketInfo] = []
    @Published var showSignals: Bool = false

    var sortBy: MarketModule.SortBy = .highestCap {
        didSet {
            syncState()
        }
    }

    init(marketInfos: [MarketInfo], timePeriod: HsTimePeriod) {
        let premiumEnabled = purchaseManager.activated(.advancedSearch)

        internalMarketInfos = marketInfos
        self.timePeriod = timePeriod

        showSignals = premiumEnabled && watchlistManager.showSignals
        self.premiumEnabled = premiumEnabled

        purchaseManager.$activeFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeFeatures in
                self?.premiumEnabled = activeFeatures.contains(.advancedSearch)
                self?.syncShowSignals()
            }
            .store(in: &cancellables)

        syncState()
    }

    private func syncShowSignals() {
        showSignals = premiumEnabled && watchlistManager.showSignals
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

    func set(showSignals: Bool) {
        stat(page: .markets, section: .searchResults, event: .showSignals(shown: showSignals))
        syncState()
        watchlistManager.showSignals = showSignals

        self.showSignals = premiumEnabled && showSignals
    }
}
