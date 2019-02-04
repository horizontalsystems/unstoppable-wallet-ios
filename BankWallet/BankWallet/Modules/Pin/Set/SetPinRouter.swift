import UIKit

protocol SetPinDelegate: class {
    func onSetPin()
}

class SetPinRouter {
}

extension SetPinRouter: ISetPinRouter {

    func navigateToMain() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module())
    }

}

extension SetPinRouter {

    static func module() -> UIViewController {
        let router = SetPinRouter()
        let interactor = PinInteractor(pinManager: App.shared.pinManager)
        let presenter = SetPinPresenter(interactor: interactor, router: router)
        let controller = PinViewController(delegate: presenter)

        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationController.navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationController.navigationBar.prefersLargeTitles = true

        interactor.delegate = presenter
        presenter.view = controller

        return navigationController
    }

}
