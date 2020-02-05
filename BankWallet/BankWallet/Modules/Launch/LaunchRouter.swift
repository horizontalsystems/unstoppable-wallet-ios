import UIKit
import StorageKit

class LaunchRouter {

    static func module() -> UIViewController {
        let interactor: ILaunchInteractor = LaunchInteractor(
                accountManager: App.shared.accountManager,
                pinManager: App.shared.pinManager,
                keychainKit: App.shared.keychainKit,
                localStorage: App.shared.localStorage
        )
        let presenter: ILaunchPresenter = LaunchPresenter(interactor: interactor)

        switch presenter.launchMode {
        case .noPasscode: return NoPasscodeViewController()
        case .welcome: return WelcomeScreenRouter.module()
        case .unlock: return LockScreenRouter.module(delegate: App.shared.lockManager, appStart: true)
        case .main: return MainRouter.module()
        }
    }

}
