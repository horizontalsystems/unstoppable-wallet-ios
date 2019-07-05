import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func showRestoreWords(delegate: IRestoreDelegate) {
        viewController?.navigationController?.pushViewController(RestoreWordsRouter.module(delegate: delegate), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let router = RestoreRouter()
        let presenter = RestorePresenter(router: router, accountCreator: App.shared.accountCreator)
        let viewController = RestoreViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

}
