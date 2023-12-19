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
public extension InteractiveTransitionDelegate {
    func start(direction _: TransitionDirection) {}
    func move(direction _: TransitionDirection, percent _: CGFloat) {}
    func end(direction _: TransitionDirection, cancelled _: Bool) {}
    func fail(direction _: TransitionDirection) {}
}
