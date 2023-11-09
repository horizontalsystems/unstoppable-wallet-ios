import UIKit
import SnapKit

class MovingPresentAnimation: BaseAnimation {
    private let animationCurve: UIView.AnimationOptions

    init(duration: TimeInterval, animationCurve: UIView.AnimationOptions) {
        self.animationCurve = animationCurve
        super.init(duration: duration)
    }

   override func animator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        let to = transitionContext.view(forKey: .to)

        to?.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.top.greaterThanOrEqualToSuperview().inset(transitionContext.containerView.safeAreaInsets.top)
        }

        return UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration,
                delay: 0,
                options: animationCurve,
                animations: {
                    to?.superview?.layoutIfNeeded()
                }, completion: { position in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
   }

}
