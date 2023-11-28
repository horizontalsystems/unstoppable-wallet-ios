class MarketService {
    private let keyTabIndex = "market-tab-index"

    private let userDefaultsStorage: UserDefaultsStorage
    private let launchScreenManager: LaunchScreenManager

    init(userDefaultsStorage: UserDefaultsStorage, launchScreenManager: LaunchScreenManager) {
        self.userDefaultsStorage = userDefaultsStorage
        self.launchScreenManager = launchScreenManager
    }
}

extension MarketService {
    var initialTab: MarketModule.Tab {
        switch launchScreenManager.launchScreen {
        case .auto:
            if let storedIndex: Int = userDefaultsStorage.value(for: keyTabIndex), let storedTab = MarketModule.Tab(rawValue: storedIndex) {
                return storedTab
            }

            return .overview
        case .balance, .marketOverview:
            return .overview
        case .watchlist:
            return .watchlist
        }
    }

    func set(tab: MarketModule.Tab) {
        userDefaultsStorage.set(value: tab.rawValue, for: keyTabIndex)
    }
}
