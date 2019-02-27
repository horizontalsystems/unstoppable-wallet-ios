import UIKit

class UnlinkRouter {
    weak var viewController: UIViewController?
}

extension UnlinkRouter: IUnlinkRouter {

    func showGuestModule() {
        UIApplication.shared.keyWindow?.set(newRootController: GuestRouter.module())
    }

}

extension UnlinkRouter {

    static func module() -> UIViewController {
        let router = UnlinkRouter()
        let interactor = UnlinkInteractor(authManager: App.shared.authManager)
        let presenter = UnlinkPresenter(router: router, interactor: interactor)
        let viewController = UnlinkViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
