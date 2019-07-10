import UIKit

class BackupRouter {
    weak var viewController: UIViewController?
    weak var unlockDelegate: IUnlockDelegate?
}

extension BackupRouter: IBackupRouter {

    func showUnlock() {
        viewController?.present(UnlockPinRouter.module(delegate: unlockDelegate, enableBiometry: false, cancelable: true), animated: true)
    }

    func showBackup(accountType: AccountType, delegate: IBackupDelegate) {
        guard let module = BackupRouter.module(accountType: accountType, delegate: delegate) else {
            return
        }

        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func close() {
        viewController?.navigationController?.dismiss(animated: true)
    }

}

extension BackupRouter {

    static func module(account: Account) -> UIViewController {
        let router = BackupRouter()
        let interactor = BackupInteractor(accountManager: App.shared.accountManager, pinManager: App.shared.pinManager)
        let presenter = BackupPresenter(interactor: interactor, router: router, account: account)

        let viewController = BackupController(delegate: presenter)
        let navigationViewController = WalletNavigationController(rootViewController: viewController)

        router.viewController = viewController
        router.unlockDelegate = presenter

        return navigationViewController
    }

    static func module(accountType: AccountType, delegate: IBackupDelegate) -> UIViewController? {
        switch accountType {
        case .mnemonic(let words, _, _):
            return BackupWordsRouter.module(delegate: delegate, words: words)
        default:
            return nil
        }
    }

}
