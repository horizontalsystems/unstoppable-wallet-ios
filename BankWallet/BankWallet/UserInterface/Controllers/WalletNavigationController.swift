import UIKit

class WalletNavigationController: UINavigationController {

    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    private func commonInit() {
        navigationBar.prefersLargeTitles = true
        modalPresentationStyle = .fullScreen
        navigationBar.tintColor = AppTheme.navigationBarTintColor
        // set navigation theme for iOS less than 13
        guard #available(iOS 13.0, *) else {
            navigationBar.barStyle = App.theme.navigationBarStyle
            let colorImage = UIImage(color: AppTheme.navigationBarBackgroundColor)
            navigationBar.setBackgroundImage(colorImage, for: .default)
            navigationBar.shadowImage = UIImage()
            return
        }
    }

    open override var childForStatusBarStyle: UIViewController? {
        self.topViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        self.topViewController
    }

}
