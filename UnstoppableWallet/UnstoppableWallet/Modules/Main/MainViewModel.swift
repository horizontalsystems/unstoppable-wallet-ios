import Combine
import Foundation
import RxSwift

class MainViewModel: ObservableObject {
    private let keyTab = "main-tab"

    private let launchScreenManager = Core.shared.launchScreenManager
    private let userDefaultsStorage = Core.shared.userDefaultsStorage
    private let accountManager = Core.shared.accountManager

    private let disposeBag = DisposeBag()

    @Published private(set) var showMarket: Bool

    @Published var selectedTab: Tab = .wallet {
        didSet {
            userDefaultsStorage.set(value: selectedTab.rawValue, for: keyTab)

            if oldValue == .wallet, selectedTab == .wallet {
                let currentTimestamp = Date().timeIntervalSince1970

                if currentTimestamp - lastTimeStamp < 0.3 {
                    if accountManager.accounts.count > 1 {
                        Coordinator.shared.present(type: .bottomSheet) { _ in
                            SwitchAccountView()
                        }

                        stat(page: .main, event: .open(page: .switchWallet))
                    }
                } else {
                    lastTimeStamp = currentTimestamp
                }
            }
        }
    }

    private var lastTimeStamp: TimeInterval = 0

    init() {
        showMarket = launchScreenManager.showMarket

        launchScreenManager.showMarketObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.showMarket = $0 })
            .disposed(by: disposeBag)

        selectedTab = initialTab
    }

    private var initialTab: Tab {
        switch launchScreenManager.launchScreen {
        case .auto:
            if let storedValue: String = userDefaultsStorage.value(for: keyTab), let storedTab = Tab(rawValue: storedValue) {
                switch storedTab {
                case .settings: return .wallet
                default: return storedTab
                }
            }

            return .wallet
        case .balance:
            return .wallet
        case .marketOverview, .watchlist:
            return .markets
        }
    }
}

extension MainViewModel {
    var lastCreatedAccount: Account? {
        accountManager.popLastCreatedAccount()
    }
}

extension MainViewModel {
    enum Tab: String, Hashable, CaseIterable, Identifiable {
        case markets
        case wallet
        case transactions
        case settings

        var id: String {
            rawValue
        }
    }
}
