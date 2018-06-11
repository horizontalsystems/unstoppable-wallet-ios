import Foundation

class TransactionsRouter {
    weak var viewController: UIViewController?
}

extension TransactionsRouter: TransactionsRouterProtocol {

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let router = TransactionsRouter()
        let presenter = TransactionsPresenter(router: router)
        let viewController = TransactionsViewController(viewDelegate: presenter)

        router.viewController = viewController

        return viewController
    }

}
