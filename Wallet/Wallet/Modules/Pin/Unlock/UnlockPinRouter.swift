import UIKit

class UnlockPinRouter {
    weak var viewController: UIViewController?

    var completion: (() -> ())?
}

extension UnlockPinRouter: IUnlockPinRouter {

    func dismiss() {
        viewController?.dismiss(animated: true) {
            self.completion?()
        }
    }

}

extension UnlockPinRouter {

    static func module(cancelable: Bool = false, completion: (() -> ())? = nil) {
        let biometricManager = BiometricManager()

        let router = UnlockPinRouter()
        let interactor = UnlockPinInteractor(pinManager: PinManager.shared, biometricManager: biometricManager, appHelper: App.shared)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router, configuration: .init(cancellable: cancelable))
        let controller = PinViewController(delegate: presenter)

        router.completion = completion
        biometricManager.delegate = interactor
        interactor.delegate = presenter
        presenter.view = controller

        let navigationController = WalletNavigationController.show(rootViewController: controller, customWindow: true)
        navigationController.setNavigationBarHidden(true, animated: false)
        router.viewController = navigationController
    }

}
