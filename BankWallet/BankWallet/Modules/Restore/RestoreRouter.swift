import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
    weak var restoreDelegate: IRestoreDelegate?
}

extension RestoreRouter: IRestoreRouter {

    func showRestoreWords() {
        viewController?.navigationController?.pushViewController(RestoreWordsRouter.module(delegate: restoreDelegate), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let router = RestoreRouter()
        let interactor = RestoreInteractor(accountManager: App.shared.accountManager)
        let presenter = RestorePresenter(interactor: interactor, router: router)
        let viewController = RestoreViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController
        router.restoreDelegate = interactor

        return WalletNavigationController(rootViewController: viewController)
    }

}
