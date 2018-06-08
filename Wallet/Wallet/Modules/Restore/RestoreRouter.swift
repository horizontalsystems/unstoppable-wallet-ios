import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: RestoreRouterProtocol {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static var viewController: UIViewController {
        let router = RestoreRouter()
        let interactor = RestoreInteractor()
        let presenter = RestorePresenter(delegate: interactor, router: router)
        let viewController = RestoreViewController(viewDelegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.barStyle = .blackTranslucent
        navigationController.navigationBar.tintColor = .cryptoYellow
        return navigationController
    }

}
