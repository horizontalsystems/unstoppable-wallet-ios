import Combine
import Foundation
import MarketKit

class MarketAdvancedSearchResultsViewModel: ObservableObject {
    private static let showSignalKey = "advanced_search_show_signal_key"

    private let currencyManager = App.shared.currencyManager
    private let purchaseManager = App.shared.purchaseManager
    private let userDefaultsStorage = App.shared.userDefaultsStorage
    private var cancellables = Set<AnyCancellable>()

    private let internalMarketInfos: [MarketInfo]
    let timePeriod: HsTimePeriod

    private var showSignalsVar: Bool {
        get {
            userDefaultsStorage.value(for: Self.showSignalKey) ?? false
        }
        set {
            userDefaultsStorage.set(value: newValue, for: Self.showSignalKey)
        }
    }

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

        showSignals = premiumEnabled && showSignalsVar
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
        showSignals = premiumEnabled && showSignalsVar
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
        showSignalsVar = showSignals

        self.showSignals = premiumEnabled && showSignals
    }
}
