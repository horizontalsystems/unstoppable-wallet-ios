import UIKit

class ManageAccountsRouter {
    weak var viewController: UIViewController?
}

extension ManageAccountsRouter: IManageAccountsRouter {

    func showUnlink(account: Account, predefinedAccountType: PredefinedAccountType) {
        viewController?.present(UnlinkRouter.module(account: account, predefinedAccountType: predefinedAccountType), animated: true)
    }

    func showBackup(account: Account, predefinedAccountType: PredefinedAccountType) {
        let module = BackupRouter.module(account: account, predefinedAccountType: predefinedAccountType)
        viewController?.present(module, animated: true)
    }

    func showCreateWallet(predefinedAccountType: PredefinedAccountType) {
        let module = CreateWalletRouter.module(presentationMode: .inApp, predefinedAccountType: predefinedAccountType)
        viewController?.present(module, animated: true)
    }

    func showRestore(predefinedAccountType: PredefinedAccountType) {
        //todo
//        let module = RestoreCoinsRouter.module(presentationMode: .inApp, predefinedAccountType: predefinedAccountType)
//        viewController?.present(module, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageAccountsRouter {

    static func module(mode: PresentationMode) -> UIViewController {
        let router = ManageAccountsRouter()
        let interactor = ManageAccountsInteractor(predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager, accountManager: App.shared.accountManager, accountCreator: App.shared.accountCreator)
        let presenter = ManageAccountsPresenter(mode: mode, interactor: interactor, router: router)
        let viewController = ManageAccountsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    enum PresentationMode {
        case pushed
        case presented
    }

}
