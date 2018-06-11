import Foundation

class WalletRouter {
    weak var viewController: UIViewController?
}

extension WalletRouter: WalletRouterProtocol {

}

extension WalletRouter {

    static func module() -> UIViewController {
        let router = WalletRouter()
        let presenter = WalletPresenter(router: router)
        let viewController = WalletViewController(viewDelegate: presenter)

        router.viewController = viewController

        return viewController
    }

}
