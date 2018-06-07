import Foundation

class RestoreWalletModule {

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

protocol RestoreWalletViewDelegate {
    func cancelDidTap()
}

protocol RestoreWalletViewProtocol: class {
}

protocol RestoreWalletPresenterDelegate {
}

protocol RestoreWalletPresenterProtocol: class {
}

protocol RestoreWalletRouterProtocol {
    func close()
}
