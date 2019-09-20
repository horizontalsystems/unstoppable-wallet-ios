import UIKit

class LockScreenRouter {
    weak var viewController: UIViewController?

    private let appStart: Bool
    private var delegate: IUnlockDelegate?

    init(appStart: Bool, delegate: IUnlockDelegate?) {
        self.appStart = appStart
        self.delegate = delegate
    }
}


extension LockScreenRouter: ILockScreenRouter {

    func dismiss() {
        if appStart {
            UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module())
        } else {
            delegate?.onUnlock()
            viewController?.dismiss(animated: false)
        }
    }

}

extension LockScreenRouter {

    static func module(delegate: IUnlockDelegate? = nil, enableBiometry: Bool = true, appStart: Bool = false) -> UIViewController {

        let router = LockScreenRouter(appStart: appStart, delegate: delegate)
        let presenter = LockScreenPresenter(router: router)

        let unlockController = UnlockPinRouter.module(delegate: presenter, enableBiometry: enableBiometry, appStart: appStart)
        let rateListController = RateListRouter.module()

        let viewController = LockScreenController(viewControllers: [rateListController, unlockController])
        router.viewController = viewController

        viewController.modalTransitionStyle = .crossDissolve

        return viewController
    }

}
