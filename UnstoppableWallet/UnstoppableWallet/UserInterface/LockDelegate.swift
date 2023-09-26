import UIKit

class LockDelegate {
    var viewController: UIViewController?

    func onLock() {
        let module = UnlockModule.appUnlockView(autoDismiss: true).toViewController()
        module.modalPresentationStyle = .fullScreen
        viewController?.visibleController.present(module, animated: false)
    }
}
