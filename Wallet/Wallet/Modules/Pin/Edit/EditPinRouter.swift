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

    static func module(from presentingController: UIViewController?) {
        let router = EditPinRouter()
        let interactor = PinInteractor(pinManager: App.shared.pinManager)
        let presenter = EditPinPresenter(interactor: interactor, router: router)
        let controller = PinViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = controller
        router.viewController = controller

        presentingController?.present(WalletNavigationController(rootViewController: controller), animated: true)
    }

}
