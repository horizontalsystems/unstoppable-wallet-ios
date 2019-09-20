import UIKit

class LockRouter: ILockRouter {
    weak var viewController: UIViewController?

    func showUnlock(delegate: IUnlockDelegate?) {
        var controller = viewController

        while let presentedController = controller?.presentedViewController {
            controller = presentedController
        }

        controller?.present(LockScreenRouter.module(delegate: delegate), animated: true)
    }

}
