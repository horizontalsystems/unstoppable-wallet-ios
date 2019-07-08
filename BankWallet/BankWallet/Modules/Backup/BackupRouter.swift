import UIKit

class BackupRouter {
    weak var viewController: UIViewController?
    weak var unlockDelegate: IUnlockDelegate?
}

extension BackupRouter: IBackupRouter {

    func showUnlock() {
        viewController?.present(UnlockPinRouter.module(unlockDelegate: unlockDelegate, enableBiometry: false, cancelable: true), animated: true)
    }

    func show(words: [String], delegate: IBackupDelegate) {
        viewController?.navigationController?.pushViewController(BackupWordsRouter.module(delegate: delegate, words: words), animated: true)
    }

    func showEOS(account: Account, delegate: IBackupDelegate) {
        print("eos account!")
    }

    func close() {
        viewController?.navigationController?.dismiss(animated: true)
    }

}

extension BackupRouter {

    static func module(account: Account) -> UIViewController {
        let router = BackupRouter()
        let interactor = BackupInteractor(accountId: account.id, accountManager: App.shared.accountManager)
        let presenter = BackupPresenter(interactor: interactor, router: router, account: account)

        let viewController = BackupController(delegate: presenter)
        let navigationViewController = WalletNavigationController(rootViewController: viewController)

        router.viewController = viewController
        router.unlockDelegate = presenter

        return navigationViewController
    }

}
