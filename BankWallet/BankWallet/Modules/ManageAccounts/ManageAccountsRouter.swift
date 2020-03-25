import UIKit
import ThemeKit

class ManageAccountsRouter {
    weak var viewController: UIViewController?
    weak var restoreController: UIViewController?
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

    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate) {
        let module = RestoreRouter.module(predefinedAccountType: predefinedAccountType, mode: .presented, proceedMode: .next, delegate: delegate)
        restoreController = module
        viewController?.present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

    func showSettings(coins: [Coin], delegate: IBlockchainSettingsDelegate?) {
        restoreController?.navigationController?.pushViewController(BlockchainSettingsListRouter.module(selectedCoins: coins, proceedMode: .restore, canSave: false, delegate: delegate), animated: true)
    }

    func showRestoreCoins(predefinedAccountType: PredefinedAccountType, accountType: AccountType, proceedMode: RestoreRouter.ProceedMode, delegate: IRestoreCoinsDelegate) {
        restoreController?.navigationController?.pushViewController(RestoreCoinsRouter.module(proceedMode: proceedMode, predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: delegate), animated: true)
    }

    func closeRestore() {
        restoreController?.dismiss(animated: true)
    }

}

extension ManageAccountsRouter {

    static func module() -> UIViewController {
        let restoreSequenceFactory = RestoreSequenceManager(walletManager: App.shared.walletManager, settingsManager: App.shared.coinSettingsManager, accountCreator: App.shared.accountCreator, accountManager: App.shared.accountManager)

        let router = ManageAccountsRouter()
        let interactor = ManageAccountsInteractor(predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager, accountManager: App.shared.accountManager, accountCreator: App.shared.accountCreator)
        let presenter = ManageAccountsPresenter(interactor: interactor, router: router, restoreSequenceFactory: restoreSequenceFactory)
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
