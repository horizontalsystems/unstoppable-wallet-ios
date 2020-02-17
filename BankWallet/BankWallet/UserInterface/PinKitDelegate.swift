import UIKit
import PinKit

class PinKitDelegate {
    var viewController: UIViewController?
}

extension PinKitDelegate: IPinKitDelegate {

    func onLock(delegate: IUnlockDelegate) {
        var controller = viewController

        while let presentedController = controller?.presentedViewController {
            controller = presentedController
        }

        controller?.present(LockScreenRouter.module(pinKit: App.shared.pinKit, appStart: false), animated: true)
    }

}
