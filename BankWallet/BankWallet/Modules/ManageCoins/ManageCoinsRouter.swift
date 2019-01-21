import UIKit

class ManageCoinsRouter {
    weak var viewController: UIViewController?
}

extension ManageCoinsRouter: IManageCoinsRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageCoinsRouter {

    static func module(from presentingController: UIViewController?) {
        let router = ManageCoinsRouter()
        let interactor = ManageCoinsInteractor(coinManager: App.shared.coinManager, storage: App.shared.grdbStorage, async: true)
        let presenter = ManageCoinsPresenter(interactor: interactor, router: router, state: ManageCoinsPresenterState())
        let viewController = ManageCoinsViewController(delegate: presenter)

        interactor.delegate = presenter
        router.viewController = viewController

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationController.navigationBar.tintColor = AppTheme.navigationBarTintColor
        presenter.view = viewController

        presentingController?.present(navigationController, animated: true)
    }

}
