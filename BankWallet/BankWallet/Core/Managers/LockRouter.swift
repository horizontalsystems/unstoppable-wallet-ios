import UIKit

class LockRouter: ILockRouter {
    weak var viewController: UIViewController?

    func showUnlock(delegate: IUnlockDelegate?) {
        var controller = viewController

        while let presentedController = controller?.presentedViewController {
            controller = presentedController
        }

        controller?.present(UnlockPinRouter.module(unlockDelegate: delegate), animated: true)
    }

}
