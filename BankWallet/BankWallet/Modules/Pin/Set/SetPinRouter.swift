import UIKit

class SetPinRouter {
    weak var viewController: UIViewController?
}

extension SetPinRouter: ISetPinRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension SetPinRouter {

    static func module() -> UIViewController {
        let router = SetPinRouter()
        let interactor = PinInteractor(pinManager: App.shared.pinManager)
        let presenter = SetPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

}
