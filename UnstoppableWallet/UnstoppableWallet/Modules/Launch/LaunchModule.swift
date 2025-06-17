import UIKit

enum LaunchModule {
    static func viewController() -> UIViewController {
        let service = LaunchService(
            accountManager: Core.shared.accountManager,
            passcodeManager: Core.shared.passcodeManager,
            passcodeLockManager: Core.shared.passcodeLockManager,
            localStorage: Core.shared.localStorage
        )

        switch service.launchMode {
        case .passcodeNotSet: return NoPasscodeViewController(mode: .noPasscode)
        case .cannotCheckPasscode: return NoPasscodeViewController(mode: .cannotCheckPasscode)
        case .intro: return WelcomeScreenViewController.instance(onFinish: {})
        case .unlock: return AppUnlockView().toViewController()
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
