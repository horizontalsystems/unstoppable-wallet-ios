import UIKit

protocol IUnlockDelegate: class {
    func onUnlock()
    func onCancelUnlock()
}

class UnlockPinRouter {
    weak var viewController: UIViewController?

    private let delegate: IUnlockDelegate

    private let unlockMode: UnlockMode

    init(unlockMode: UnlockMode, delegate: IUnlockDelegate) {
        self.unlockMode = unlockMode
        self.delegate = delegate
    }

}

extension UnlockPinRouter: IUnlockPinRouter {

    func dismiss(didUnlock: Bool) {
        if didUnlock {
            delegate.onUnlock()
        } else {
            delegate.onCancelUnlock()
        }

        if unlockMode == .simple {
            viewController?.dismiss(animated: false)
        }
    }

}

extension UnlockPinRouter {

    static func module(delegate: IUnlockDelegate, enableBiometry: Bool, unlockMode: UnlockMode) -> UIViewController {
        let biometricManager = BiometricManager()
        let lockoutUntilDateFactory = LockoutUntilDateFactory(currentDateProvider: CurrentDateProvider())
        let uptimeProvider = UptimeProvider()
        let lockoutManager = LockoutManager(secureStorage: App.shared.secureStorage, uptimeProvider: uptimeProvider, lockoutTimeFrameFactory: lockoutUntilDateFactory)
        let timer = OneTimeTimer()

        let router = UnlockPinRouter(unlockMode: unlockMode, delegate: delegate)
        let interactor = UnlockPinInteractor(pinManager: App.shared.pinManager, biometricManager: biometricManager, lockoutManager: lockoutManager, timer: timer, secureStorage: App.shared.secureStorage)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router, configuration: .init(cancellable: unlockMode == .simple, enableBiometry: enableBiometry))

        let viewController = PinViewController(delegate: presenter, unlockMode: unlockMode)

        biometricManager.delegate = interactor
        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        viewController.modalTransitionStyle = .crossDissolve

        return viewController
    }

}
