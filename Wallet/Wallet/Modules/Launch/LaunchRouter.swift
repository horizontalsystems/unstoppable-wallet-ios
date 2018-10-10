import UIKit

class LaunchRouter {
    var window: UIWindow?
    var replace: Bool = false

    static func presenter(window: UIWindow?, replace: Bool = false) -> ILaunchPresenter {
        let router = LaunchRouter()
        let interactor = LaunchInteractor(wordsManager: App.shared.wordsManager, lockManager: LockManager.shared, pinManager: PinManager.shared)
        let presenter = LaunchPresenter(interactor: interactor, router: router)

        interactor.delegate = presenter
        router.window = window
        router.replace = replace

        return presenter
    }

    private func show(viewController: UIViewController) {
        if replace, let window = window {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = viewController
            })
        } else {
            window?.rootViewController = viewController
        }
    }
}

extension LaunchRouter: ILaunchRouter {

    func showMainModule() {
        show(viewController: MainRouter.module())
    }

    func showGuestModule() {
        show(viewController: GuestRouter.module())
    }

}
