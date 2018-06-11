import Foundation

class BackupRouter {
    weak var viewController: UIViewController?
}

extension BackupRouter: BackupRouterProtocol {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension BackupRouter {

    static var viewController: UIViewController {
        let router = BackupRouter()
        let interactor = BackupInteractor(walletDataProvider: Factory.instance.stubWalletDataProvider, indexesProvider: Factory.instance.randomGenerator)
        let presenter = BackupPresenter(delegate: interactor, router: router)
        let viewController = BackupNavigationController(viewDelegate: presenter)

        interactor.presenter = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
