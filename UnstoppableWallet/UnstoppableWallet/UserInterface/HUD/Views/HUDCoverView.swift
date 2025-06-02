import UIKit

open class HUDCoverView: UIView, CoverViewInterface {
    public weak var delegate: CoverViewDelegate?
    public var transparent: Bool = false
    public var coverBackgroundColor: UIColor? = nil

    public var onTapCover: (() -> Void)? = nil
    public var isVisible: Bool { !isHidden }

    public func show(animated _: Bool) {}

    public func hide(animated _: Bool, completion _: (() -> Void)?) {}
}

public protocol CoverViewInterface {
    var delegate: CoverViewDelegate? { get set }
    var transparent: Bool { get set }

    var onTapCover: (() -> Void)? { get set }
    var coverBackgroundColor: UIColor? { get set }
    var isVisible: Bool { get }
    var appearDuration: TimeInterval { get }
    var disappearDuration: TimeInterval { get }
    var animationCurve: UIView.AnimationOptions { get }

    func show(animated: Bool)
    func hide(animated: Bool, completion: (() -> Void)?)
}

public extension CoverViewInterface {
    var appearDuration: TimeInterval {
        HUDTheme.coverAppearDuration
    }

    var disappearDuration: TimeInterval {
        HUDTheme.coverDisappearDuration
    }

    var animationCurve: UIView.AnimationOptions {
        HUDTheme.coverAnimationCurve
    }
}

public protocol CoverViewDelegate: AnyObject {
    func willShow()
    func didShow()

    func willHide()
    func didHide()
}

extension CoverViewDelegate {
    func willShow() {}

    func didShow() {}

    func willHide() {}

    func didHide() {}
}
