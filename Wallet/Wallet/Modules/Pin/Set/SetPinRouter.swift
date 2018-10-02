import UIKit

class SetPinRouter {
    weak var viewController: UIViewController?

    var completion: (() -> ())?
}

extension SetPinRouter: ISetPinRouter {

    func dismiss() {
        viewController?.dismiss(animated: true) {
            self.completion?()
        }
    }

}

extension SetPinRouter {

    static func module(from presentingController: UIViewController? = nil, completion: (() -> ())? = nil) {

        let router = SetPinRouter()
        let interactor = PinInteractor(pinManager: PinManager.shared)
        let presenter = SetPinPresenter(interactor: interactor, router: router)
        let controller = PinViewController(delegate: presenter)

        router.completion = completion
        interactor.delegate = presenter
        presenter.view = controller

        if let presentingController = presentingController {
            router.viewController = controller
            presentingController.navigationController?.present(WalletNavigationController(rootViewController: controller), animated: true)
        } else {
            router.viewController = WalletNavigationController.show(rootViewController: controller, customWindow: true)
        }
    }

}
