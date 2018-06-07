import Foundation

class RestoreWalletRouter {
    weak var viewController: UIViewController?
}

extension RestoreWalletRouter: RestoreWalletRouterProtocol {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreWalletRouter {

    static var viewController: UIViewController {
        let router = RestoreWalletRouter()
        let interactor = RestoreWalletInteractor()
        let presenter = RestoreWalletPresenter(delegate: interactor, router: router)
        let viewController = RestoreWalletViewController(viewDelegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
