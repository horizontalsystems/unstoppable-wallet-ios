import UIKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func showManageKeys() {
        viewController?.present(WalletNavigationController(rootViewController: ManageAccountsRouter.module(mode: .presented)), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageWalletsRouter {

    static func module() -> UIViewController {
        let router = ManageWalletsRouter()
        let presenter = ManageWalletsPresenter(router: router, appConfigProvider: App.shared.appConfigProvider, walletManager: App.shared.walletManager, accountCreator: App.shared.accountCreator)
        let viewController = ManageWalletsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

}
