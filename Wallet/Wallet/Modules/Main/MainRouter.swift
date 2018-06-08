import UIKit

class MainRouter {
    weak var viewController: UIViewController?
}

extension MainRouter: MainRouterProtocol {

}

extension MainRouter {

    static var viewController: UIViewController {
        let router = MainRouter()
        let presenter = MainPresenter(router: router)

        let viewControllers = [
            WalletRouter.viewController,
            TransactionsRouter.viewController,
            SettingsRouter.viewController
        ]

        let viewController = MainViewController(viewDelegate: presenter, viewControllers: viewControllers)

        router.viewController = viewController

        return viewController
    }

}
