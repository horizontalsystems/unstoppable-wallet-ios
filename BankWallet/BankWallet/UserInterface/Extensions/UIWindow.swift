import UIKit

extension UIWindow {

    func set(newRootController: UIViewController) {
        backgroundColor = AppTheme.controllerBackground

        let transition = CATransition()
        transition.type = CATransitionType.fade
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)

        layer.add(transition, forKey: kCATransition)

        let oldRootController = rootViewController

        rootViewController = newRootController

        oldRootController?.dismiss(animated: false) {
            oldRootController?.view.removeFromSuperview()
        }
    }

}
