import Foundation

class RestoreWalletRouter: RestoreWalletRouterProtocol {

    private weak var viewController: UIViewController?

    static var viewController: UIViewController {
        let router = RestoreWalletRouter()
        let presenter = RestoreWalletPresenter()
        let interactor = RestoreWalletInteractor(router: router, presenter: presenter)
        let viewController = RestoreWalletViewController(delegate: interactor)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

protocol RestoreWalletViewDelegate {
    func cancelDidTap()
}

protocol RestoreWalletViewProtocol: class {
}

protocol RestoreWalletPresenterProtocol {
}

protocol RestoreWalletRouterProtocol {
    func close()
}
