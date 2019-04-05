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
        navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationBar.prefersLargeTitles = true
        navigationBar.shadowImage = UIImage()
        let colorImage = UIImage(color: AppTheme.navigationBarBackgroundColor)
        navigationBar.setBackgroundImage(colorImage, for: .default)
    }

}
