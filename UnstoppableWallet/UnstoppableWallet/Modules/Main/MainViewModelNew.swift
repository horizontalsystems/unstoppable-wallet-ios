import Combine
import Foundation
import RxSwift

class MainViewModelNew: ObservableObject {
    private let keyTab = "main-tab"

    private let launchScreenManager = Core.shared.launchScreenManager
    private let userDefaultsStorage = Core.shared.userDefaultsStorage
    private let accountManager = Core.shared.accountManager
    private let lockManager = Core.shared.lockManager

    private let releaseNotesService = ReleaseNotesService()
    private let jailbreakService = JailbreakService()

    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    @Published private(set) var showMarket: Bool
    @Published var switchAccountPresented = false
    @Published var accountsLostPresented = false

    @Published var selectedTab: Tab = .wallet {
        didSet {
            userDefaultsStorage.set(value: selectedTab.rawValue, for: keyTab)

            if oldValue == .wallet, selectedTab == .wallet {
                let currentTimestamp = Date().timeIntervalSince1970

                if currentTimestamp - lastTimeStamp < 0.3 {
                    if accountManager.accounts.count > 1 {
                        switchAccountPresented = true
                    }
                } else {
                    lastTimeStamp = currentTimestamp
                }
            }
        }
    }

    @Published var releaseNotesUrl: URL? {
        didSet {
            if releaseNotesUrl == nil {
                handleNextAlert()
            }
        }
    }

    @Published var jailbreakPresented = false {
        didSet {
            if !jailbreakPresented {
                handleNextAlert()
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

        lockManager.$isLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleNextAlert() }
            .store(in: &cancellables)

        accountManager.$accountsLost
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleNextAlert() }
            .store(in: &cancellables)

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

extension MainViewModelNew {
    func handleNextAlert() {
        guard !lockManager.isLocked else {
            return
        }

        if let releaseNotesUrl = releaseNotesService.releaseNotesUrl {
            self.releaseNotesUrl = releaseNotesUrl
        } else if jailbreakService.needToShowAlert {
            jailbreakPresented = true
            jailbreakService.setAlertShown()
        } else if accountManager.accountsLost {
            accountsLostPresented = true
            accountManager.accountsLost = false
        }
        // else if let deepLink = deepLinkService.deepLink {
        //     handleDeepLink(deepLink: deepLink)
        // }
    }
}

extension MainViewModelNew {
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
