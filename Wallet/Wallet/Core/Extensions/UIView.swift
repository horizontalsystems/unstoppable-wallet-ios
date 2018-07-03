import UIKit

extension UIView {

    public var width: CGFloat {
        return frame.size.width
    }

    public var height: CGFloat {
        return frame.size.height
    }

    public var x: CGFloat {
        return frame.origin.x
    }

    public var y: CGFloat {
        return frame.origin.y
    }

    public var bottom: CGFloat {
        return frame.origin.y + frame.size.height
    }

    public var size: CGSize {
        return frame.size
    }

    public func set(hidden: Bool, animated: Bool = false) {
        if animated {
            if !hidden {
                alpha = 0
                isHidden = false
            }
            UIView.animate(withDuration: AppTheme.animationDuration, animations: {
                self.alpha = hidden ? 0 : 0
            }, completion: { _ in
                self.alpha = 1
                self.isHidden = hidden
            })
        } else {
            isHidden = hidden
        }
    }

}
