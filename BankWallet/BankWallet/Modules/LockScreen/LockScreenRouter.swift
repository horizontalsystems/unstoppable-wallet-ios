import UIKit

class LockScreenRouter {
    weak var viewController: UIViewController?

    private let appStart: Bool
    private let delegate: IUnlockDelegate

    init(appStart: Bool, delegate: IUnlockDelegate) {
        self.appStart = appStart
        self.delegate = delegate
    }

}


extension LockScreenRouter: ILockScreenRouter {

    func dismiss() {
        delegate.onUnlock()

        if appStart {
            UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module())
        } else {
            viewController?.dismiss(animated: false)
        }
    }

}

extension LockScreenRouter {

    static func module(delegate: IUnlockDelegate, appStart: Bool) -> UIViewController {
        let router = LockScreenRouter(appStart: appStart, delegate: delegate)
        let presenter = LockScreenPresenter(router: router)

        let rateListController = RateListRouter.module()
        let unlockController = UnlockPinRouter.module(delegate: presenter, enableBiometry: true, unlockMode: .complex)

        let viewController = LockScreenController(viewControllers: [unlockController, rateListController])
        router.viewController = viewController

        viewController.modalTransitionStyle = .crossDissolve

        return viewController
    }

}
