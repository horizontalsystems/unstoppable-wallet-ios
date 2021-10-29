import RxSwift
import RxRelay
import StorageKit

class LaunchScreenManager {
    private let keyLaunchScreen = "launch-screen"

    private let storage: StorageKit.ILocalStorage

    private let launchScreenRelay = PublishRelay<LaunchScreen>()

    var launchScreen: LaunchScreen {
        get {
            if let rawValue: String = storage.value(for: keyLaunchScreen), let launchScreen = LaunchScreen(rawValue: rawValue) {
                return launchScreen
            }

            return .auto
        }
        set {
            storage.set(value: newValue.rawValue, for: keyLaunchScreen)
            launchScreenRelay.accept(newValue)
        }
    }

    init(storage: StorageKit.ILocalStorage) {
        self.storage = storage
    }

    var launchScreenObservable: Observable<LaunchScreen> {
        launchScreenRelay.asObservable()
    }

}
