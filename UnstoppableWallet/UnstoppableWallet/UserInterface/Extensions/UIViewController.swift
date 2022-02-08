import UIKit

extension UIViewController {

    var visibleController: UIViewController {
        var controller: UIViewController = self
        while let presentedController = controller.presentedViewController {
            controller = presentedController
        }

        return controller
    }

}
