import UIKit
import ActionSheet

class SyncModeRouter {
    weak var viewController: UIViewController?
    weak var agreementDelegate: IAgreementDelegate?
}

extension SyncModeRouter: ISyncModeRouter {

    func showAgreement() {
        viewController?.present(AgreementRouter.module(agreementDelegate: agreementDelegate), animated: true)
    }

    func navigateToSetPin() {
        viewController?.present(SetPinRouter.module(), animated: true)
    }

}

extension SyncModeRouter {

    static func module(mode: SyncModuleStartMode) -> UIViewController {
        let router = SyncModeRouter()

        let interactor = SyncModeInteractor(authManager: App.shared.authManager, wordsManager: App.shared.wordsManager)
        let presenter = SyncModePresenter(interactor: interactor, router: router, state: SyncModeState(), mode: mode)
        let viewController = SyncModeViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController
        router.agreementDelegate = interactor

        return viewController
    }

}
