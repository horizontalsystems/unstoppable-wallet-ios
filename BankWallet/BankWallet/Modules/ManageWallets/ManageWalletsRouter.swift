import UIKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageWalletsRouter {

    static func module() -> UIViewController {
        let router = ManageWalletsRouter()
        let interactor = ManageWalletsInteractor(appConfigProvider: App.shared.appConfigProvider, walletManager: App.shared.walletManager, accountManager: App.shared.accountManager, storage: App.shared.grdbStorage)
        let presenter = ManageWalletsPresenter(interactor: interactor, router: router, state: ManageWalletsPresenterState())
        let viewController = ManageWalletsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        let navigationController = WalletNavigationController(rootViewController: viewController)
        navigationController.navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationController.navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationController.navigationBar.prefersLargeTitles = true

        return navigationController
    }

}
