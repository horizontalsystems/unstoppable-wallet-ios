import StorageKit
import UIKit

class LaunchModule {
    static func viewController() -> UIViewController {
        let service = LaunchService(
            accountManager: App.shared.accountManager,
            passcodeManager: App.shared.passcodeManager,
            keychainKit: App.shared.keychainKit,
            localStorage: App.shared.localStorage
        )

        switch service.launchMode {
        case .passcodeNotSet: return NoPasscodeViewController(mode: .noPasscode)
        case .cannotCheckPasscode: return NoPasscodeViewController(mode: .cannotCheckPasscode)
        case .intro: return WelcomeScreenViewController()
        case .unlock: return UnlockModule.appUnlockView(appStart: true).toViewController()
        case .main: return MainModule.instance()
        }
    }
}

extension LaunchModule {
    enum LaunchMode {
        case passcodeNotSet
        case cannotCheckPasscode
        case intro
        case unlock
        case main
    }
}
