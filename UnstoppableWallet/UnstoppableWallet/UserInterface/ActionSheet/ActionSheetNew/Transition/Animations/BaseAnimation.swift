import Foundation
import UIKit

class BaseAnimation: NSObject {
    let duration: TimeInterval

    init(duration: TimeInterval) {
        self.duration = duration
    }

    func animator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        fatalError("Must be implemented by inheritors")
    }

}

extension BaseAnimation: UIViewControllerAnimatedTransitioning  {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        animator(using: transitionContext).startAnimation()
    }

}
