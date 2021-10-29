import StorageKit

class MarketService {
    private let keyTabIndex = "market-tab-index"

    private let storage: StorageKit.ILocalStorage
    private let launchScreenManager: LaunchScreenManager

    init(storage: StorageKit.ILocalStorage, launchScreenManager: LaunchScreenManager) {
        self.storage = storage
        self.launchScreenManager = launchScreenManager
    }

}

extension MarketService {

    var initialTab: MarketModule.Tab {
        switch launchScreenManager.launchScreen {
        case .auto:
            if let storedIndex: Int = storage.value(for: keyTabIndex), let storedTab = MarketModule.Tab(rawValue: storedIndex) {
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
        storage.set(value: tab.rawValue, for: keyTabIndex)
    }

}
