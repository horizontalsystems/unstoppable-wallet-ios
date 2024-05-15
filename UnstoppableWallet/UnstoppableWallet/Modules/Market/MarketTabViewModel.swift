import Combine

class MarketTabViewModel: ObservableObject {
    private let keyTab = "market-tab"

    private let userDefaultsStorage = App.shared.userDefaultsStorage
    private let launchScreenManager = App.shared.launchScreenManager

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
