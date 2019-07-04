import UIKit

protocol IAgreementDelegate: class {
    func onConfirmAgreement()
}

class AgreementRouter {
    weak var viewController: UIViewController?
    weak var agreementDelegate: IAgreementDelegate?
}

extension AgreementRouter: IAgreementRouter {

    func dismissWithSuccess() {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.agreementDelegate?.onConfirmAgreement()
        }
    }

}

extension AgreementRouter {

    static func module(agreementDelegate: IAgreementDelegate?) -> UIViewController {
        let router = AgreementRouter()
        let interactor = AgreementInteractor(localStorage: UserDefaultsStorage.shared)
        let presenter = AgreementPresenter(router: router, interactor: interactor)
        let viewController = AgreementViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        router.viewController = viewController
        router.agreementDelegate = agreementDelegate

        return viewController
    }

}
