import UIKit

class LaunchRouter {
    var window: UIWindow?

    private func show(viewController: UIViewController) {
        window?.rootViewController = viewController
    }
}

extension LaunchRouter: ILaunchRouter {

    func showWelcomeModule() {
        show(viewController: WelcomeScreenRouter.module())
    }

    func showMainModule() {
        show(viewController: MainRouter.module())
    }

    func showUnlockModule() {
        show(viewController: UnlockPinRouter.module(appStart: true))
    }

}

extension LaunchRouter {

    static func presenter(window: UIWindow?) -> ILaunchPresenter {
        let router = LaunchRouter()
        let interactor = LaunchInteractor(accountManager: App.shared.accountManager, pinManager: App.shared.pinManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = LaunchPresenter(interactor: interactor, router: router)

        interactor.delegate = presenter
        router.window = window

        return presenter
    }

}
