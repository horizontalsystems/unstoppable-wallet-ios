import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func navigateToMain() {
        viewController?.view.endEditing(true)

        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let controller = MainRouter.module()

        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = controller
        })
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let router = RestoreRouter()
        let interactor = RestoreInteractor(mnemonic: Factory.instance.mnemonicManager, loginManager: Factory.instance.loginManager)
        let presenter = RestorePresenter(interactor: interactor, router: router)
        let viewController = RestoreViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.barStyle = .blackTranslucent
        navigationController.navigationBar.tintColor = .cryptoYellow
        return navigationController
    }

}
