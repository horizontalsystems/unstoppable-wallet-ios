import UIKit

extension CALayer {
    static let moveAnimationKey = "move_animation"
    static let opacityAnimationKey = "opacity_animation"

    class func moveAnimation(layer: CALayer, to: CGPoint) -> CABasicAnimation {
        let from = layer.presentation()?.value(forKeyPath: "position") as? CGPoint

        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = from ?? layer.position
        animation.toValue = to
        animation.duration = .themeAnimationDuration
        layer.position = to

        return animation
    }

    class func opacityAnimation(layer: CALayer, hide: Bool) -> CABasicAnimation {
        let from = layer.presentation()?.value(forKeyPath: "opacity") as? Float

        let to: Float = hide ? 0.0 : 1.0
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = from ?? layer.opacity
        animation.toValue = to
        animation.duration = .themeAnimationDuration
        layer.opacity = to

        return animation
    }

    class func perform(withoutAnimation: Bool = true, duration: TimeInterval? = nil, _ action: () -> Void, completion: (() -> ())? = nil) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration ?? .themeAnimationDuration)
        CATransaction.setDisableActions(withoutAnimation)

        CATransaction.setCompletionBlock {
            DispatchQueue.main.async {
                completion?()
            }
        }

        action()
        CATransaction.commit()
    }

}
