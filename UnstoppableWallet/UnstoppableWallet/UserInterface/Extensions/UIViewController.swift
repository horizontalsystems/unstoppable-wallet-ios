import UIKit

extension UIViewController {

    var visibleController: UIViewController {
        var controller: UIViewController = self
        while let presentedController = controller.presentedViewController {
            controller = presentedController
        }

        return controller
    }

    static var visibleController: UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first

        return keyWindow?.rootViewController?.visibleController
    }

}
