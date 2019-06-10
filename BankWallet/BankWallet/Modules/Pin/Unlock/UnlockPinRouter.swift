import UIKit

protocol IUnlockDelegate: class {
    func onUnlock()
    func onCancelUnlock()
}

class UnlockPinRouter {
    weak var unlockDelegate: IUnlockDelegate?
    weak var viewController: UIViewController?

    private let appStart: Bool

    init(appStart: Bool) {
        self.appStart = appStart
    }
}

extension UnlockPinRouter: IUnlockPinRouter {

    func dismiss(didUnlock: Bool) {
        if appStart {
            UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module())
        } else {
            if didUnlock {
                unlockDelegate?.onUnlock()
            } else {
                unlockDelegate?.onCancelUnlock()
            }
            viewController?.dismiss(animated: false)
        }
    }

}

extension UnlockPinRouter {

    static func module(unlockDelegate: IUnlockDelegate? = nil, enableBiometry: Bool = true, appStart: Bool = false, cancelable: Bool = false) -> UIViewController {
        let biometricManager = BiometricManager()
        let lockoutUntilDateFactory = LockoutUntilDateFactory(currentDateProvider: CurrentDateProvider())
        let uptimeProvider = UptimeProvider()
        let lockoutManager = LockoutManager(secureStorage: App.shared.secureStorage, uptimeProvider: uptimeProvider, lockoutTimeFrameFactory: lockoutUntilDateFactory)
        let timer = OneTimeTimer()

        let router = UnlockPinRouter(appStart: appStart)
        let interactor = UnlockPinInteractor(pinManager: App.shared.pinManager, biometricManager: biometricManager, localStorage: App.shared.localStorage, lockoutManager: lockoutManager, timer: timer, secureStorage: App.shared.secureStorage)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router, configuration: .init(cancellable: cancelable, enableBiometry: enableBiometry))
        let viewController = PinViewController(delegate: presenter)

        biometricManager.delegate = interactor
        interactor.delegate = presenter
        presenter.view = viewController
        router.unlockDelegate = unlockDelegate
        router.viewController = viewController

        viewController.modalTransitionStyle = .crossDissolve

        return viewController
    }

}
