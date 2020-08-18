import UIKit

extension UITabBarItem {

    func setDotBadge(visible: Bool) {
        if visible {
            badgeValue = "●"
            badgeColor = .clear
            setBadgeTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], for: .normal)
        } else {
            badgeValue = nil
        }
    }

}
