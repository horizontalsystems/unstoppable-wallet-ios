import UIKit

class WalletNavigationController: UINavigationController {
    var window: UIWindow?

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationBar.prefersLargeTitles = true
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationBar.prefersLargeTitles = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
