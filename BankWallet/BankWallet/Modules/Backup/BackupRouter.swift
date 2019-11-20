import UIKit

class BackupRouter {
    weak var viewController: UIViewController?
}

extension BackupRouter: IBackupRouter {

    func showUnlock(delegate: IUnlockDelegate) {
        viewController?.present(UnlockPinRouter.module(delegate: delegate, enableBiometry: false, unlockMode: .simple), animated: true)
    }

    func showBackup(account: Account, predefinedAccountType: IPredefinedAccountType, delegate: IBackupDelegate) {
        guard let module = BackupRouter.module(account: account, predefinedAccountType: predefinedAccountType, delegate: delegate) else {
            return
        }

        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func close() {
        viewController?.navigationController?.dismiss(animated: true)
    }

}

extension BackupRouter {

    static func module(account: Account, predefinedAccountType: IPredefinedAccountType) -> UIViewController {
        let router = BackupRouter()
        let interactor = BackupInteractor(backupManager: App.shared.backupManager, pinManager: App.shared.pinManager)
        let presenter = BackupPresenter(interactor: interactor, router: router, account: account, predefinedAccountType: predefinedAccountType)

        let viewController = BackupController(delegate: presenter)
        let navigationViewController = WalletNavigationController(rootViewController: viewController)

        router.viewController = viewController

        return navigationViewController
    }

    static func module(account: Account, predefinedAccountType: IPredefinedAccountType, delegate: IBackupDelegate) -> UIViewController? {
        switch account.type {
        case let .mnemonic(words, _, _):
            return BackupWordsRouter.module(delegate: delegate, predefinedAccountType: predefinedAccountType, words: words, isBackedUp: account.backedUp)
        case let .eos(account, activePrivateKey):
            return BackupEosRouter.module(delegate: delegate, account: account, activePrivateKey: activePrivateKey)
        default:
            return nil
        }
    }

}
