import UIKit
import PinKit

class PinKitDelegate {
    var viewController: UIViewController?
}

extension PinKitDelegate: IPinKitDelegate {

    func onLock(delegate: IUnlockDelegate) {
        viewController?.visibleController.present(LockScreenRouter.module(pinKit: App.shared.pinKit, appStart: false), animated: false)
    }

}
