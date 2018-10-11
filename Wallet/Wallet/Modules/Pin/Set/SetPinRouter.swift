import UIKit

protocol SetPinDelegate: class {
    func onSetPin()
}

class SetPinRouter {
    weak var navigationController: UINavigationController?
}

extension SetPinRouter: ISetPinRouter {

    func navigateToMain() {
        navigationController?.topViewController?.view.endEditing(true)

        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = MainRouter.module()
        })
    }

}

extension SetPinRouter {

    static func module() -> UIViewController {
        let router = SetPinRouter()
        let interactor = PinInteractor(pinManager: App.shared.pinManager)
        let presenter = SetPinPresenter(interactor: interactor, router: router)
        let controller = PinViewController(delegate: presenter)

        let navigationController = WalletNavigationController(rootViewController: controller)

        interactor.delegate = presenter
        presenter.view = controller
        router.navigationController = navigationController

        return navigationController
    }

}
