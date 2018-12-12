import UIKit

protocol IUnlockDelegate: class {
    func onUnlock()
}

class UnlockPinRouter {
    weak var unlockDelegate: IUnlockDelegate?
    weak var viewController: UIViewController?
}

extension UnlockPinRouter: IUnlockPinRouter {

    func dismiss(didUnlock: Bool) {
        viewController?.view.endEditing(true)
        viewController?.dismiss(animated: true, completion: {
            if didUnlock {
                self.unlockDelegate?.onUnlock()
            }
        })
    }

}

extension UnlockPinRouter {

    static func module(unlockDelegate: IUnlockDelegate?, cancelable: Bool = false) -> UIViewController {
        let biometricManager = BiometricManager()
        let lockoutManager = LockoutManagerNew()
        let timer = OneTimeTimer()

        let router = UnlockPinRouter()
        let interactor = UnlockPinInteractor(pinManager: App.shared.pinManager, biometricManager: biometricManager, localStorage: App.shared.localStorage, lockoutManager: lockoutManager, timer: timer)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router, configuration: .init(cancellable: cancelable))
        let view = PinViewController(delegate: presenter)

        biometricManager.delegate = interactor
        interactor.delegate = presenter
        presenter.view = view
        router.unlockDelegate = unlockDelegate
        router.viewController = view

        return view
    }

}
