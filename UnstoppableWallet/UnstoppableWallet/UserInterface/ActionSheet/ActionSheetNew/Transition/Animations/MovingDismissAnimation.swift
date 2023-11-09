import UIKit

class MovingDismissAnimation: BaseAnimation {
    private let animationCurve: UIView.AnimationCurve

    init(duration: TimeInterval, animationCurve: UIView.AnimationCurve) {
        self.animationCurve = animationCurve
        super.init(duration: duration)
    }

    override func animator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        guard let from = transitionContext.view(forKey: .from) else {
            return UIViewPropertyAnimator(duration: duration, curve: animationCurve)
        }

        let animator = UIViewPropertyAnimator(duration: duration, curve: animationCurve) {
            from.frame = from.frame.offsetBy(dx: 0, dy: from.height)
        }
        
        animator.addCompletion { (position) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        return animator
    }

}

extension MovingDismissAnimation {

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        animator(using: transitionContext)
    }

}