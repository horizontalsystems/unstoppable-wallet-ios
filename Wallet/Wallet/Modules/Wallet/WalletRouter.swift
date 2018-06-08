import Foundation

class WalletRouter {
    weak var viewController: UIViewController?
}

extension WalletRouter: WalletRouterProtocol {

}

extension WalletRouter {

    static var viewController: UIViewController {
        let router = WalletRouter()
        let presenter = WalletPresenter(router: router)
        let viewController = WalletViewController(viewDelegate: presenter)

        router.viewController = viewController

        return viewController
    }

}
