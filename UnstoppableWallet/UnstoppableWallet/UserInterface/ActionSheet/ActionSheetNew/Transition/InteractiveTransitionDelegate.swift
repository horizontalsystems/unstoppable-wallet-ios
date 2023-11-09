import Foundation
import UIKit

public enum TransitionDirection: Int { case present, dismiss }

public protocol InteractiveTransitionDelegate: AnyObject {
    func start(direction: TransitionDirection)
    func move(direction: TransitionDirection, percent: CGFloat)
    func end(direction: TransitionDirection, cancelled: Bool)
    func fail(direction: TransitionDirection)
}

// Make pure swift option methods for delegate
extension InteractiveTransitionDelegate {
    public func start(direction: TransitionDirection) {}
    public func move(direction: TransitionDirection, percent: CGFloat) {}
    public func end(direction: TransitionDirection, cancelled: Bool) {}
    public func fail(direction: TransitionDirection) {}
}
