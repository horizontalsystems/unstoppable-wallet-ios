import UIKit

extension UIView {

    func set(hidden: Bool, animated: Bool = false, duration: TimeInterval = .themeAnimationDuration, completion: ((Bool) -> ())? = nil) {
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

    func shakeView(_ block: (() -> Void)? = nil) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(block)

        let animation = CAKeyframeAnimation(keyPath: "transform")
        let fromAnimation = NSValue(caTransform3D: CATransform3DMakeTranslation(-5, 0, 0))
        let toAnimation = NSValue(caTransform3D: CATransform3DMakeTranslation(5, 0, 0))

        animation.values = [fromAnimation, toAnimation]
        animation.autoreverses = true
        animation.repeatCount = 2
        animation.duration = 0.07
        layer.add(animation, forKey: "shakeAnimation")

        CATransaction.commit()
    }

}
