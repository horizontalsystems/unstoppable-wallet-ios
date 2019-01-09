import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

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

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.barStyle = .blackTranslucent
        navigationController.navigationBar.tintColor = .cryptoYellow
        return navigationController
    }

}
