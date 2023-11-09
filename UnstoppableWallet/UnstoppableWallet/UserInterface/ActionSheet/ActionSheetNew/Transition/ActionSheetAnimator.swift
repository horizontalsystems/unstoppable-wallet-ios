import UIKit

public class ActionSheetAnimator: NSObject, UIViewControllerTransitioningDelegate {
    var driver: TransitionDriver?
    private let configuration: ActionSheetConfiguration
    public weak var interactiveTransitionDelegate: InteractiveTransitionDelegate? {
        didSet {
            driver?.interactiveTransitionDelegate = interactiveTransitionDelegate
        }
    }

    public init(configuration: ActionSheetConfiguration) {
        self.configuration = configuration
        super.init()

        if configuration.style == .sheet {
            driver = TransitionDriver()
        }
    }

    var interactiveTransitionStarted: Bool {
        driver?.interactiveTransitionStarted ?? false
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        driver?.add(to: presented)
        return ActionSheetPresentationController(driver: driver, presentedViewController: presented,
                                                                presenting: presenting ?? source,
                                                                configuration: configuration)
    }
    
    // Animation
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch configuration.style {
        case .sheet: return MovingPresentAnimation(duration: configuration.presentAnimationDuration, animationCurve: configuration.presentAnimationCurve)
        case .alert: return AlphaPresentAnimation(duration: configuration.presentAnimationDuration, animationCurve: configuration.presentAnimationCurve)
        }
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch configuration.style {
        case .sheet: return MovingDismissAnimation(duration: configuration.dismissAnimationDuration, animationCurve: configuration.dismissAnimationCurve)
        case .alert: return AlphaDismissAnimation(duration: configuration.dismissAnimationDuration, animationCurve: configuration.dismissAnimationCurve)
        }
    }
    
    // Interaction
    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        driver
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        driver
    }

    deinit {
//        print("deinit \(self)")
    }

}
