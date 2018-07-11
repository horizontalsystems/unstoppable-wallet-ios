import UIKit

extension UIView {

    public func set(hidden: Bool, animated: Bool = false, duration: TimeInterval = AppTheme.defaultAnimationDuration, completion: ((Bool) -> ())? = nil) {
        if isHidden == hidden {
            return
        }
        if animated {
            if !hidden {
                alpha = 0
                isHidden = false
            }
            UIView.animate(withDuration: duration, animations: {
                self.alpha = hidden ? 0 : 1
            }, completion: { success in
                self.alpha = 1
                self.isHidden = hidden
                completion?(success)
            })
        } else {
            isHidden = hidden
            completion?(true)
        }
    }

}
