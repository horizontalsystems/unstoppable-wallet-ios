import UIKit
import PinKit

class LockScreenRouter {
    weak var viewController: UIViewController?

    private let appStart: Bool

    init(appStart: Bool) {
        self.appStart = appStart
    }

}


extension LockScreenRouter: ILockScreenRouter {

    func dismiss() {
        if appStart {
            UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module())
        } else {
            viewController?.dismiss(animated: false)
        }
    }

}

extension LockScreenRouter {

    static func module(pinKit: IPinKit, appStart: Bool) -> UIViewController {
        let router = LockScreenRouter(appStart: appStart)
        let presenter = LockScreenPresenter(router: router)

        let rateListController = RateListRouter.module()
        let unlockController = pinKit.unlockPinModule(delegate: presenter, enableBiometry: true, presentationStyle: .complex, cancellable: false)

        let viewController = LockScreenController(viewControllers: [unlockController, rateListController])
        router.viewController = viewController

        viewController.modalTransitionStyle = .crossDissolve

        return viewController
    }

}
