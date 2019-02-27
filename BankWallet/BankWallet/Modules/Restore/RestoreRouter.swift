import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
    weak var agreementDelegate: IAgreementDelegate?
}

extension RestoreRouter: IRestoreRouter {

    func showAgreement() {
        viewController?.present(AgreementRouter.module(agreementDelegate: agreementDelegate), animated: true)
    }

    func navigateToSetPin() {
        viewController?.present(SetPinRouter.module(), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let router = RestoreRouter()
        let interactor = RestoreInteractor(authManager: App.shared.authManager, wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RestorePresenter(interactor: interactor, router: router)
        let viewController = RestoreViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController
        router.agreementDelegate = interactor

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.barStyle = .blackTranslucent
        navigationController.navigationBar.tintColor = .cryptoYellow
        return navigationController
    }

}
