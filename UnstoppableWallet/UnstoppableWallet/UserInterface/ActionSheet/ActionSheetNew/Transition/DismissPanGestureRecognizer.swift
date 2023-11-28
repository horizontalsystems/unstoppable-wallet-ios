import UIKit

class DismissPanGestureRecognizer: UIPanGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began { return }
        super.touchesBegan(touches, with: event)
        state = .began
    }
}
