import UIKit

protocol UnlockDelegate: class {
    func onUnlock()
}

class UnlockPinRouter {
    weak var viewController: UIViewController?
}

extension UnlockPinRouter: IUnlockPinRouter {

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension UnlockPinRouter {

    static func module(unlockDelegate: UnlockDelegate?, cancelable: Bool = false) {
        let biometricManager = BiometricManager()

        let router = UnlockPinRouter()
        let interactor = UnlockPinInteractor(pinManager: App.shared.pinManager, biometricManager: biometricManager, localStorage: App.shared.localStorage)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router, configuration: .init(cancellable: cancelable))
        let controller = PinViewController(delegate: presenter)

        biometricManager.delegate = interactor
        interactor.delegate = presenter
        interactor.unlockDelegate = unlockDelegate
        presenter.view = controller

        let navigationController = WalletNavigationController.show(rootViewController: controller, customWindow: true)
        navigationController.setNavigationBarHidden(true, animated: false)
        router.viewController = navigationController
    }

}
