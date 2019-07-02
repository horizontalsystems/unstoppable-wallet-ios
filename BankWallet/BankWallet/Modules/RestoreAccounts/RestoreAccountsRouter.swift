import UIKit

class RestoreAccountsRouter {
    weak var viewController: UIViewController?
}

extension RestoreAccountsRouter: IRestoreAccountsRouter {

    func showRestore(type: RestoreType) {
//         viewController?.present(UnlinkRouter.module(accountId: accountId), animated: true)
    }

}

extension RestoreAccountsRouter {

    static func module() -> UIViewController {
        let router = RestoreAccountsRouter()
        let presenter = RestoreAccountsPresenter(router: router)
        let viewController = RestoreAccountsViewController(delegate: presenter)

        router.viewController = viewController

        return viewController
    }

}
