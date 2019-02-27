import UIKit

class LaunchRouter {
    var window: UIWindow?

    static func presenter(window: UIWindow?) -> ILaunchPresenter {
        let router = LaunchRouter()
        let interactor = LaunchInteractor(authManager: App.shared.authManager, lockManager: App.shared.lockManager, pinManager: App.shared.pinManager, appConfigProvider: App.shared.appConfigProvider, localStorage: App.shared.localStorage)
        let presenter = LaunchPresenter(interactor: interactor, router: router)

        interactor.delegate = presenter
        router.window = window

        return presenter
    }

    private func show(viewController: UIViewController) {
        window?.rootViewController = viewController
    }
}

extension LaunchRouter: ILaunchRouter {

    func showUnlockModule() {
        show(viewController: UnlockPinRouter.module(appStart: true))
    }

    func showMainModule() {
        show(viewController: MainRouter.module())
    }

    func showGuestModule() {
        show(viewController: GuestRouter.module())
    }

    func showSetPinModule() {
        show(viewController: SetPinRouter.module())
    }

    func showBackupModule() {
        show(viewController: BackupRouter.module(mode: .initial))
    }

}
