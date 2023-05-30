import UIKit
import PinKit

class PinKitDelegate {
    var viewController: UIViewController?
}

extension PinKitDelegate: IPinKitDelegate {

    func onLock() {
        viewController?.visibleController.present(LockScreenModule.viewController(pinKit: App.shared.pinKit, appStart: false), animated: false)
    }

}
