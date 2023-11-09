import UIKit

class TransitionDriver: UIPercentDrivenInteractiveTransition {
    private weak var presentedController: UIViewController?
    weak var interactiveTransitionDelegate: InteractiveTransitionDelegate?

    var panRecognizer: UIPanGestureRecognizer?

    var direction: TransitionDirection = .present
    var speedMultiplier: CGFloat = 1
    func add(to controller: UIViewController) {
        presentedController = controller
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handle(_ :)))
        presentedController?.view.addGestureRecognizer(panRecognizer!)
    }

    override var wantsInteractiveStart: Bool {
        get {
            switch direction {
            case .present:
                return false
            case .dismiss:
                let gestureIsActive = panRecognizer?.state == .began
                return gestureIsActive
            }
        }
        
        set { }
    }

    var interactiveTransitionStarted: Bool {
        guard let recognizer = panRecognizer else {
            return false
        }
        switch recognizer.state {
        case .began, .changed: return true
        default: return false
        }
    }


    @objc private func handle(_ recognizer: UIPanGestureRecognizer) {
        switch direction {
        case .present:
            handlePresentation(recognizer: recognizer)
        case .dismiss:
            handleDismiss(recognizer: recognizer)
        }
    }

    deinit {
//        print("deinit \(self)")
    }

}

extension TransitionDriver {                    // Gesture Handling
    
    private func handlePresentation(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            pause()
            interactiveTransitionDelegate?.start(direction: .present)
        case .changed:
            let increment = -recognizer.incrementToBottom(maxTranslation: maxTranslation)
            update(percentComplete + increment)
            interactiveTransitionDelegate?.move(direction: .present, percent: percentComplete + increment)
        case .ended, .cancelled:
            speedMultiplier = recognizer.swipeMultiplier(maxTranslation: maxTranslation)
            if speedMultiplier < 0.5 {
                speedMultiplier = 1
                cancel()
                interactiveTransitionDelegate?.end(direction: .present, cancelled: true)
            } else {
                finish()
                interactiveTransitionDelegate?.end(direction: .present, cancelled: false)
            }
            
        case .failed:
            cancel()
            interactiveTransitionDelegate?.fail(direction: .present)

        default:
            break
        }
    }
    
    private func handleDismiss(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            pause() // Pause allows to detect isRunning
            if !isRunning {
                speedMultiplier = recognizer.swipeMultiplier(maxTranslation: maxTranslation)
                presentedController?.dismiss(animated: true) // Start the new one
                interactiveTransitionDelegate?.start(direction: .dismiss)
            }
        
        case .changed:
            let newValue = percentComplete + recognizer.incrementToBottom(maxTranslation: maxTranslation)
            update(newValue)
            interactiveTransitionDelegate?.move(direction: .dismiss, percent: newValue)
        case .ended, .cancelled:
            speedMultiplier = recognizer.swipeMultiplier(maxTranslation: maxTranslation)
            if speedMultiplier < 0.5 {
                finish()
                interactiveTransitionDelegate?.end(direction: .dismiss, cancelled: false)
            } else {
                speedMultiplier = 1
                cancel()
                interactiveTransitionDelegate?.end(direction: .dismiss, cancelled: true)
            }

        case .failed:
            speedMultiplier = 1
            cancel()
            interactiveTransitionDelegate?.fail(direction: .dismiss)
        default:
            break
        }
    }
    
    var maxTranslation: CGFloat {
        presentedController?.view.frame.height ?? 0
    }
    
    private var isRunning: Bool {
        percentComplete != 0
    }
}

private extension UIPanGestureRecognizer {

    func projectedLocation(decelerationRate: UIScrollView.DecelerationRate) -> CGPoint {
        guard let view = view else {
            return .zero
        }
        var loc = location(in: view)
        let velocityOffset = velocity(in: view)

        loc.x += velocityOffset.x / (1 - decelerationRate.rawValue) / 1000
        loc.y += velocityOffset.y / (1 - decelerationRate.rawValue) / 1000

        return velocityOffset
    }

    func swipeMultiplier(maxTranslation: CGFloat) -> CGFloat {
        let endLocation = projectedLocation(decelerationRate: .fast)
        guard endLocation.y.sign == .plus else {    // user swipe up after try dismiss
            return 1
        }
        return max(0.3, min(1, abs(maxTranslation / endLocation.y)))  // when calculate speed for dismiss animation make range 0.3...1 for multiplier
    }
    
    func incrementToBottom(maxTranslation: CGFloat) -> CGFloat {
        let translation = self.translation(in: view).y
        setTranslation(.zero, in: nil)
        
        let percentIncrement = translation / maxTranslation
        return percentIncrement
    }

}
