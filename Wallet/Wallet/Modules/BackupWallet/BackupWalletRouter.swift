import Foundation

class BackupWalletRouter {
    weak var viewController: UIViewController?
}

extension BackupWalletRouter: BackupWalletRouterProtocol {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension BackupWalletRouter {

    static var viewController: UIViewController {
        let router = BackupWalletRouter()
        let interactor = BackupWalletInteractor(wordsProvider: WalletManager(), indexesProvider: RandomProvider())
        let presenter = BackupWalletPresenter(delegate: interactor, router: router)
        let viewController = BackupWalletNavigationController(viewDelegate: presenter)

        interactor.presenter = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
