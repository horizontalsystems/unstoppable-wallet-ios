import UIKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func showRestore(type: PredefinedAccountType, delegate: IRestoreDelegate) {
        guard let module = RestoreRouter.module(type: type, delegate: delegate) else {
            return
        }

        viewController?.present(WalletNavigationController(rootViewController: module), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageWalletsRouter {

    static func module() -> UIViewController {
        let router = ManageWalletsRouter()
        let presenter = ManageWalletsPresenter(router: router, appConfigProvider: App.shared.appConfigProvider, walletManager: App.shared.walletManager, walletCreator: App.shared.walletCreator, accountCreator: App.shared.accountCreator)
        let viewController = ManageWalletsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        let navigationController = WalletNavigationController(rootViewController: viewController)
        navigationController.navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationController.navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationController.navigationBar.prefersLargeTitles = true

        return navigationController
    }

}
