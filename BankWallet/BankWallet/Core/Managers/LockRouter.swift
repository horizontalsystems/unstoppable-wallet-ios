import UIKit

class LockRouter: ILockRouter {
    weak var viewController: UIViewController?

    func showUnlock(delegate: IUnlockDelegate?) {
        var controller = viewController

        while let presentedController = controller?.presentedViewController {
            controller = presentedController
        }

        if let controller = controller {
            controller.present(LockScreenRouter.module(delegate: delegate), animated: true)
        } else {
            let baseController: Any = viewController ?? "nil"
            UIAlertController.showSimpleAlert(message: "Failed to show Pin Lock module: top presented view controller not found.\nBase controller: \(baseController)")
        }
    }

}
