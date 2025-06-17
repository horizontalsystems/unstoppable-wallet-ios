import Combine

class MarketTabViewModel: ObservableObject {
    private let keyTab = "market-tab"

    private let userDefaultsStorage = Core.shared.userDefaultsStorage
    private let launchScreenManager = Core.shared.launchScreenManager

    @Published var currentTab: MarketModule.Tab {
        didSet {
            userDefaultsStorage.set(value: currentTab.rawValue, for: keyTab)
        }
    }

    init() {
        switch launchScreenManager.launchScreen {
        case .auto:
            if let storedValue: String = userDefaultsStorage.value(for: keyTab), let storedTab = MarketModule.Tab(rawValue: storedValue) {
                currentTab = storedTab
            } else {
                currentTab = .coins
            }
        case .balance, .marketOverview:
            currentTab = .coins
        case .watchlist:
            currentTab = .watchlist
        }
    }
}
