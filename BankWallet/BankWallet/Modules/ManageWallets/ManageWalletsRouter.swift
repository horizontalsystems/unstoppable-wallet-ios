import UIKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func showCreateAccount(coin: Coin, delegate: ICreateAccountDelegate) {
        viewController?.present(CreateAccountRouter.module(coin: coin, delegate: delegate), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageWalletsRouter {

    static func module() -> UIViewController {
        let router = ManageWalletsRouter()
        let presenter = ManageWalletsPresenter(router: router, appConfigProvider: App.shared.appConfigProvider, walletManager: App.shared.walletManager, walletCreator: App.shared.walletCreator)
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
