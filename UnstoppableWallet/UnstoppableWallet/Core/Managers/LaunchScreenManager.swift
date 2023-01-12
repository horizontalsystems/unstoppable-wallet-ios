import RxSwift
import RxRelay
import StorageKit

class LaunchScreenManager {
    private let keyLaunchScreen = "launch-screen"
    private let keyShowMarket = "show-market-screen"

    private let storage: StorageKit.ILocalStorage

    private let launchScreenRelay = PublishRelay<LaunchScreen>()
    private let showMarketRelay = PublishRelay<Bool>()

    var launchScreen: LaunchScreen {
        get {
            if let rawValue: String = storage.value(for: keyLaunchScreen), let launchScreen = LaunchScreen(rawValue: rawValue) {
                // check if market hidden
                if !showMarket {
                    return .auto
                }

                return launchScreen
            }

            return .auto
        }
        set {
            storage.set(value: newValue.rawValue, for: keyLaunchScreen)
            launchScreenRelay.accept(newValue)
        }
    }

    var showMarket: Bool {
        get {
            storage.value(for: keyShowMarket) ?? true
        }
        set {
            storage.set(value: newValue, for: keyShowMarket)
            showMarketRelay.accept(newValue)
        }
    }

    init(storage: StorageKit.ILocalStorage) {
        self.storage = storage
    }

    var launchScreenObservable: Observable<LaunchScreen> {
        launchScreenRelay.asObservable()
    }

    var showMarketObservable: Observable<Bool> {
        showMarketRelay.asObservable()
    }

}
