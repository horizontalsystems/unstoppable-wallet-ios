import UIKit

class AlphaDismissAnimation: BaseAnimation {
    private let animationCurve: UIView.AnimationCurve

    init(duration: TimeInterval, animationCurve: UIView.AnimationCurve) {
        self.animationCurve = animationCurve
        super.init(duration: duration)
    }

    override func animator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        let animator = UIViewPropertyAnimator(duration: duration, curve: animationCurve) {
            transitionContext.view(forKey: .from)?.alpha = 0
        }

        animator.addCompletion { (position) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        return animator
    }

}
