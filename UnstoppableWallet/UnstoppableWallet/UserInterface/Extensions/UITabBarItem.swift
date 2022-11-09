import UIKit

extension UITabBarItem {

    func setDotBadge(visible: Bool, count: Int) {
        guard visible else {
            badgeValue = nil
            return
        }

        if count == 0 {
            badgeValue = "●"
            badgeColor = .clear
            setBadgeTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], for: .normal)
        } else {
            badgeValue = "\(min(99, count))"
            badgeColor = .red
            setBadgeTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        }
    }

}
