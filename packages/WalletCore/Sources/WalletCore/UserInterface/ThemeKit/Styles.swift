import UIKit

public extension UIBlurEffect.Style {
    static var themeHud: UIBlurEffect.Style { Theme.current.hudBlurStyle }
}

public extension UIStatusBarStyle {
    static var themeDefault: UIStatusBarStyle { Theme.current.statusBarStyle }
}
