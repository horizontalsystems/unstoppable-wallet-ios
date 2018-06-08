import Foundation

class BalanceRouter {
    weak var viewController: UIViewController?
}

extension BalanceRouter: BalanceRouterProtocol {

}

extension BalanceRouter {

    static var viewController: UIViewController {
        let router = BalanceRouter()
        let presenter = BalancePresenter(router: router)
        let viewController = BalanceViewController(viewDelegate: presenter)

        router.viewController = viewController

        return viewController
    }

}
