import UIKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func showRestore(defaultAccountType: DefaultAccountType, delegate: IRestoreAccountTypeDelegate) {
        guard let module = RestoreRouter.module(defaultAccountType: defaultAccountType, mode: .presented, delegate: delegate) else {
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
        let interactor = ManageWalletsInteractor(appConfigProvider: App.shared.appConfigProvider, walletManager: App.shared.walletManager, walletFactory: App.shared.walletFactory, accountCreator: App.shared.accountCreator, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager)
        let presenter = ManageWalletsPresenter(interactor: interactor, router: router)
        let viewController = ManageWalletsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

}
