import UIKit

class BackupRouter {
    weak var viewController: UIViewController?
    weak var unlockDelegate: IUnlockDelegate?
}

extension BackupRouter: IBackupRouter {

    func showUnlock() {
        viewController?.present(UnlockPinRouter.module(delegate: unlockDelegate, enableBiometry: false, cancelable: true), animated: true)
    }

    func showBackup(account: Account, delegate: IBackupDelegate) {
        guard let module = BackupRouter.module(account: account, delegate: delegate) else {
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
        router.unlockDelegate = presenter

        return navigationViewController
    }

    static func module(account: Account, delegate: IBackupDelegate) -> UIViewController? {
        switch account.type {
        case .mnemonic(let words, _, _):
            return BackupWordsRouter.module(delegate: delegate, words: words, isBackedUp: account.backedUp)
        default:
            return nil
        }
    }

}
