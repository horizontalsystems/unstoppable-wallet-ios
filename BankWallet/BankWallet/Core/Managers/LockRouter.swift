import UIKit

class LockRouter: ILockRouter {
    weak var viewController: UIViewController?

    func showUnlock(delegate: IUnlockDelegate?) {
        var controller = viewController

        while let presentedController = controller?.presentedViewController {
            controller = presentedController
        }

        let some: Any = controller ?? "nil"
        App.shared.debugLogger?.add(log: "LockRouter will present lock from controller: \(some)")

        controller?.present(LockScreenRouter.module(delegate: delegate), animated: true)
    }

}
