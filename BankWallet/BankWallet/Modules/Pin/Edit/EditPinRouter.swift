import UIKit

class EditPinRouter {
    weak var viewController: UIViewController?
}

extension EditPinRouter: IEditPinRouter {

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension EditPinRouter {

    static func module() -> UIViewController {
        let router = EditPinRouter()
        let interactor = PinInteractor(pinManager: App.shared.pinManager)
        let presenter = EditPinPresenter(interactor: interactor, router: router)
        let controller = PinViewController(delegate: presenter)

        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationController.navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationController.navigationBar.prefersLargeTitles = true

        interactor.delegate = presenter
        presenter.view = controller
        router.viewController = controller

        return navigationController
    }

}
