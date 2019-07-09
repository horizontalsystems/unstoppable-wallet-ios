import UIKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

//    func showRestore(type: PredefinedAccountType, delegate: IRestoreAccountTypeDelegate) {
//        guard let module = RestoreRouter.module(type: type, mode: .presented, delegate: delegate) else {
//            return
//        }
//
//        viewController?.present(WalletNavigationController(rootViewController: module), animated: true)
//    }

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

        return WalletNavigationController(rootViewController: viewController)
    }

}
