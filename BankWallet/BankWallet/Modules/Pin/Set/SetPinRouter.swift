import UIKit

class SetPinRouter {
    weak var viewController: UIViewController?

    private let delegate: ISetPinDelegate

    init(delegate: ISetPinDelegate) {
        self.delegate = delegate
    }

}

extension SetPinRouter: ISetPinRouter {

    func notifyCancelled() {
        delegate.didCancelSetPin()
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension SetPinRouter {

    static func module(delegate: ISetPinDelegate) -> UIViewController {
        let router = SetPinRouter(delegate: delegate)
        let interactor = PinInteractor(pinManager: App.shared.pinManager)
        let presenter = SetPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

}
