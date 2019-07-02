import UIKit

class BackupRouter {
    weak var viewController: UIViewController?
    weak var unlockDelegate: IUnlockDelegate?
}

extension BackupRouter: IBackupRouter {

    func showUnlock() {
        viewController?.present(UnlockPinRouter.module(unlockDelegate: unlockDelegate, enableBiometry: false, cancelable: true), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension BackupRouter {

    static func module(account: Account) -> UIViewController? {
        let router = BackupRouter()
        let interactor = BackupInteractor(accountId: account.id, accountManager: App.shared.accountManager, randomManager: App.shared.randomManager)

        let presenter: IBackupPresenter

        if case let .mnemonic(words, _, _) = account.type {
            presenter = BackupWordsPresenter(interactor: interactor, router: router, words: words, confirmationWordsCount: 2)
        } else {
            return nil
        }

        let viewController = BackupNavigationController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        router.viewController = viewController
        router.unlockDelegate = interactor

        return viewController
    }

}
