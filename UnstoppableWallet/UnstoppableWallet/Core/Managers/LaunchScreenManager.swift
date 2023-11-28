import RxRelay
import RxSwift

class LaunchScreenManager {
    private let keyLaunchScreen = "launch-screen"
    private let keyShowMarket = "show-market-screen"

    private let userDefaultsStorage: UserDefaultsStorage

    private let launchScreenRelay = PublishRelay<LaunchScreen>()
    private let showMarketRelay = PublishRelay<Bool>()

    var launchScreen: LaunchScreen {
        get {
            if let rawValue: String = userDefaultsStorage.value(for: keyLaunchScreen), let launchScreen = LaunchScreen(rawValue: rawValue) {
                // check if market hidden
                if !showMarket {
                    return .auto
                }

                return launchScreen
            }

            return .auto
        }
        set {
            userDefaultsStorage.set(value: newValue.rawValue, for: keyLaunchScreen)
            launchScreenRelay.accept(newValue)
        }
    }

    var showMarket: Bool {
        get {
            userDefaultsStorage.value(for: keyShowMarket) ?? true
        }
        set {
            userDefaultsStorage.set(value: newValue, for: keyShowMarket)
            showMarketRelay.accept(newValue)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage
    }

    var launchScreenObservable: Observable<LaunchScreen> {
        launchScreenRelay.asObservable()
    }

    var showMarketObservable: Observable<Bool> {
        showMarketRelay.asObservable()
    }
}
