import UIKit

class WalletNavigationController: UINavigationController {
    private var window: UIWindow?

    @discardableResult static func show(rootViewController: UIViewController, customWindow: Bool = false) -> WalletNavigationController {
        let navigationController = WalletNavigationController(rootViewController: rootViewController)
        if customWindow {
            navigationController.window = UIWindow(frame: UIScreen.main.bounds)
            navigationController.window?.rootViewController = navigationController
            navigationController.window?.makeKeyAndVisible()
        }
        return navigationController
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationBar.prefersLargeTitles = true
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        guard let window = window else {
            super.dismiss(animated: flag, completion: completion)
            return
        }
        UIView.animate(withDuration: PinTheme.dismissAnimationDuration, animations: {
            window.frame.origin.y = UIScreen.main.bounds.height
        }, completion: { _ in
            self.window = nil
            completion?()

            super.dismiss(animated: false)
        })
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

}
