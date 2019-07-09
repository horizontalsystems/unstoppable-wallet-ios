import UIKit

class ManageAccountsRouter {
    weak var viewController: UIViewController?
}

extension ManageAccountsRouter: IManageAccountsRouter {

    func showUnlink(accountId: String) {
        viewController?.present(UnlinkRouter.module(accountId: accountId), animated: true)
    }

    func showBackup(account: Account) {
        let module = BackupRouter.module(account: account)
        viewController?.present(module, animated: true)
    }

}

extension ManageAccountsRouter {

    static func module() -> UIViewController {
        let router = ManageAccountsRouter()
        let interactor = ManageAccountsInteractor(predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager, accountManager: App.shared.accountManager)
        let presenter = ManageAccountsPresenter(interactor: interactor, router: router)
        let viewController = ManageAccountsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
