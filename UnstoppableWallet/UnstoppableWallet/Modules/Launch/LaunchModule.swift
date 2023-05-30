import UIKit
import StorageKit

class LaunchModule {

    static func viewController() -> UIViewController {
        let service = LaunchService(
                accountManager: App.shared.accountManager,
                pinKit: App.shared.pinKit,
                keychainKit: App.shared.keychainKit,
                localStorage: App.shared.localStorage
        )

        switch service.launchMode {
        case .passcodeNotSet: return NoPasscodeViewController(mode: .noPasscode)
        case .cannotCheckPasscode: return NoPasscodeViewController(mode: .cannotCheckPasscode)
        case .intro: return WelcomeScreenViewController()
        case .unlock: return LockScreenModule.viewController(pinKit: App.shared.pinKit, appStart: true)
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
