import UIKit

class LockDelegate {
    var viewController: UIViewController?

    func onLock() {
        let module = UnlockModule.appUnlockView(appStart: false).toViewController()
        module.modalPresentationStyle = .fullScreen
        viewController?.visibleController.present(module, animated: false)
    }
}
