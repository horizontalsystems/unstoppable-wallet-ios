import UIKit
import ThemeKit
import PinKit

class BackupRouter {
    weak var viewController: UIViewController?
}

extension BackupRouter: IBackupRouter {

    func showUnlock(delegate: IUnlockDelegate) {
        viewController?.present(App.shared.pinKit.unlockPinModule(delegate: delegate, enableBiometry: false, presentationStyle: .simple, cancellable: true), animated: true)
    }

    func showBackup(account: Account, predefinedAccountType: PredefinedAccountType, delegate: IBackupDelegate) {
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

    static func module(account: Account, predefinedAccountType: PredefinedAccountType) -> UIViewController {
        let router = BackupRouter()
        let interactor = BackupInteractor(backupManager: App.shared.backupManager, pinKit: App.shared.pinKit)
        let presenter = BackupPresenter(interactor: interactor, router: router, account: account, predefinedAccountType: predefinedAccountType)

        let viewController = BackupController(delegate: presenter)
        let navigationViewController = ThemeNavigationController(rootViewController: viewController)

        router.viewController = viewController

        return navigationViewController
    }

    static func module(account: Account, predefinedAccountType: PredefinedAccountType, delegate: IBackupDelegate) -> UIViewController? {
        switch account.type {
        case let .mnemonic(words, _):
            return BackupWordsRouter.module(delegate: delegate, predefinedAccountType: predefinedAccountType, words: words, isBackedUp: account.backedUp)
        case let .eos(account, activePrivateKey):
            return BackupEosRouter.module(delegate: delegate, account: account, activePrivateKey: activePrivateKey)
        default:
            return nil
        }
    }

}
