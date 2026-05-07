import Foundation
import UIKit

class BaseAnimation: NSObject {
    let duration: TimeInterval

    init(duration: TimeInterval) {
        self.duration = duration
    }

    func animator(using _: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        fatalError("Must be implemented by inheritors")
    }
}

extension BaseAnimation: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        animator(using: transitionContext).startAnimation()
    }
}
