import UIKit
import StorageKit

class LaunchRouter {

    static func module() -> UIViewController {
        let interactor: ILaunchInteractor = LaunchInteractor(
                accountManager: App.shared.accountManager,
                pinKit: App.shared.pinKit,
                keychainKit: App.shared.keychainKit,
                localStorage: App.shared.localStorage
        )
        let presenter: ILaunchPresenter = LaunchPresenter(interactor: interactor)

        switch presenter.launchMode {
        case .noPasscode: return NoPasscodeViewController(mode: .noPasscode)
        case .intro: return WelcomeScreenViewController()
        case .unlock: return LockScreenRouter.module(pinKit: App.shared.pinKit, appStart: true)
        case .main: return MainModule.instance()
        }
    }

}
