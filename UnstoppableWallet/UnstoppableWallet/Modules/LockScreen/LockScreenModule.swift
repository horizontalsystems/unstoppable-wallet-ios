import UIKit

protocol ILockScreenRouter {
    func dismiss()
}

protocol INavigationRouter: AnyObject {
    func push(viewController: UIViewController)
    func present(viewController: UIViewController)
}
