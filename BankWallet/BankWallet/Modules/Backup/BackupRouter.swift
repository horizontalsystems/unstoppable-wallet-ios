import UIKit

class BackupRouter {
    weak var navigationController: UINavigationController?
    weak var unlockDelegate: IUnlockDelegate?
}

extension BackupRouter: IBackupRouter {

    func close() {
        navigationController?.dismiss(animated: true)
    }

    func navigateToSetPin() {
        navigationController?.present(SetPinRouter.module(), animated: true)
    }

    func showUnlock() {
        navigationController?.present(UnlockPinRouter.module(unlockDelegate: unlockDelegate, cancelable: true), animated: true)
    }

}

extension BackupRouter {

    static func module(dismissMode: BackupPresenter.DismissMode) -> UIViewController {
        let router = BackupRouter()
        let interactor = BackupInteractor(authManager: App.shared.authManager, wordsManager: App.shared.wordsManager, pinManager: App.shared.pinManager, randomManager: App.shared.randomManager)
        let presenter = BackupPresenter(interactor: interactor, router: router, dismissMode: dismissMode)
        let navigationController = BackupNavigationController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = navigationController
        router.navigationController = navigationController
        router.unlockDelegate = interactor

        return navigationController
    }

}
