import UIKit

class BackupRouter {
    weak var viewController: UIViewController?
    weak var unlockDelegate: IUnlockDelegate?
    weak var agreementDelegate: IAgreementDelegate?
}

extension BackupRouter: IBackupRouter {

    func showAgreement() {
        viewController?.present(AgreementRouter.module(agreementDelegate: agreementDelegate), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

    func navigateToSetPin() {
        viewController?.present(SetPinRouter.module(), animated: true)
    }

    func showUnlock() {
        viewController?.present(UnlockPinRouter.module(unlockDelegate: unlockDelegate, enableBiometry: false, cancelable: true), animated: true)
    }

}

extension BackupRouter {

    static func module(mode: BackupPresenter.Mode) -> UIViewController {
        let router = BackupRouter()
        let interactor = BackupInteractor(authManager: App.shared.authManager, wordsManager: App.shared.wordsManager, pinManager: App.shared.pinManager, randomManager: App.shared.randomManager)
        let presenter = BackupPresenter(interactor: interactor, router: router, mode: mode)
        let viewController = BackupNavigationController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        router.viewController = viewController
        router.unlockDelegate = interactor
        router.agreementDelegate = interactor

        return viewController
    }

}
