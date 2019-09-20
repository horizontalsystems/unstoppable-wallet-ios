import UIKit

protocol IUnlockDelegate: class {
    func onUnlock()
    func onCancelUnlock()
}

class UnlockPinRouter {
    weak var viewController: UIViewController?

    private let appStart: Bool
    private var delegate: IUnlockDelegate?

    init(appStart: Bool, delegate: IUnlockDelegate?) {
        self.appStart = appStart
        self.delegate = delegate
    }
}

extension UnlockPinRouter: IUnlockPinRouter {

    func dismiss(didUnlock: Bool) {
        if appStart {
            UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module())
        } else {
            if didUnlock {
                delegate?.onUnlock()
            } else {
                delegate?.onCancelUnlock()
            }
            viewController?.dismiss(animated: false)
        }
    }

}

extension UnlockPinRouter {

    static func module(delegate: IUnlockDelegate? = nil, enableBiometry: Bool = true, appStart: Bool = false, unlockMode: UnlockMode = .complex) -> UIViewController {
        let biometricManager = BiometricManager()
        let lockoutUntilDateFactory = LockoutUntilDateFactory(currentDateProvider: CurrentDateProvider())
        let uptimeProvider = UptimeProvider()
        let lockoutManager = LockoutManager(secureStorage: App.shared.secureStorage, uptimeProvider: uptimeProvider, lockoutTimeFrameFactory: lockoutUntilDateFactory)
        let timer = OneTimeTimer()

        let router = UnlockPinRouter(appStart: appStart, delegate: delegate)
        let interactor = UnlockPinInteractor(pinManager: App.shared.pinManager, biometricManager: biometricManager, lockoutManager: lockoutManager, timer: timer, secureStorage: App.shared.secureStorage)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router, configuration: .init(cancellable: unlockMode == .simple, enableBiometry: enableBiometry))

        var insets = UIEdgeInsets.zero
        var gradient = false
        var useSafeAreaLayoutGuide = false
        if unlockMode == .simple {
            insets.bottom = PinTheme.keyboardBottomMargin
            gradient = true
            useSafeAreaLayoutGuide = true
        }
        let viewController = PinViewController(delegate: presenter, gradient: gradient, insets: insets, useSafeAreaLayoutGuide: useSafeAreaLayoutGuide)

        biometricManager.delegate = interactor
        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        viewController.modalTransitionStyle = .crossDissolve

        return viewController
    }

}
