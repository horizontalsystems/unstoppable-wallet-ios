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
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module())
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
