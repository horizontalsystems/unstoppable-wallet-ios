import UIKit

class LaunchRouter {
    var window: UIWindow?

    static func presenter(window: UIWindow?) -> ILaunchPresenter {
        let router = LaunchRouter()
        let interactor = LaunchInteractor(wordsManager: App.shared.wordsManager, lockManager: App.shared.lockManager, pinManager: App.shared.pinManager)
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

    func showMainModule() {
        show(viewController: MainRouter.module())
    }

    func showGuestModule() {
        show(viewController: GuestRouter.module())
    }

    func showSetPinModule() {
        show(viewController: SetPinRouter.module())
    }

}
