import UIKit

class LaunchRouter {

    static func module() -> UIViewController {
        let interactor: ILaunchInteractor = LaunchInteractor(accountManager: App.shared.accountManager, pinManager: App.shared.pinManager, passcodeLockManager: App.shared.passcodeLockManager, localStorage: App.shared.localStorage)
        let presenter: ILaunchPresenter = LaunchPresenter(interactor: interactor)

        switch presenter.launchMode {
        case .noPasscode: return NoPasscodeRouter.module()
        case .welcome: return WelcomeScreenRouter.module()
        case .unlock: return UnlockPinRouter.module(appStart: true)
        case .main: return MainRouter.module()
        }
    }

}
