import UIKit
import SnapKit

class AlphaPresentAnimation: BaseAnimation {
    private let animationCurve: UIView.AnimationOptions

    init(duration: TimeInterval, animationCurve: UIView.AnimationOptions) {
        self.animationCurve = animationCurve
        super.init(duration: duration)
    }

    override func animator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration,
                delay: 0,
                options: animationCurve,
                animations: {
                    transitionContext.view(forKey: .to)?.alpha = 1
                }, completion: { position in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

}
