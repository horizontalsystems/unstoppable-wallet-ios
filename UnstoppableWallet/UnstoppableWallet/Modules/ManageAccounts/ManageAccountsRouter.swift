import UIKit
import ThemeKit

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

    func showBackupRequired(account: Account, predefinedAccountType: PredefinedAccountType) {
        let module = BackupRequiredRouter.module(
                account: account,
                predefinedAccountType: predefinedAccountType,
                sourceViewController: viewController,
                text: "settings_manage_keys.delete.cant_delete".localized
        )

        viewController?.present(module, animated: true)
    }

    func showCreateWallet(predefinedAccountType: PredefinedAccountType) {
        CreateWalletModule.start(mode: .present(viewController: viewController), predefinedAccountType: predefinedAccountType)
    }

    func showRestore(predefinedAccountType: PredefinedAccountType) {
        RestoreModule.start(mode: .present(viewController: viewController), predefinedAccountType: predefinedAccountType)
    }

    func showSettings() {
        let module = AddressFormatModule.viewController()
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageAccountsRouter {

    static func module() -> UIViewController {
        let router = ManageAccountsRouter()
        let interactor = ManageAccountsInteractor(predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager, accountManager: App.shared.accountManager, derivationSettingsManager: App.shared.derivationSettingsManager, bitcoinCashCoinTypeManager: App.shared.bitcoinCashCoinTypeManager, walletManager: App.shared.walletManager)
        let presenter = ManageAccountsPresenter(interactor: interactor, router: router)
        let viewController = ManageAccountsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
