import UIKit

protocol PseudoAccessoryViewDelegate: AnyObject {
    func pseudoAccessoryView(_ pseudoAccessoryView: PseudoAccessoryView, keyboardFrameDidChange frame: CGRect)
}

public class PseudoAccessoryView: UIView {
    private let keyPathSelector = #keyPath(center)
    private var oldFrame = CGRect.zero

    weak var delegate: PseudoAccessoryViewDelegate?

    private var heightConstraint: NSLayoutConstraint?

    public var heightValue: CGFloat = 0 {
        didSet {
            heightConstraint?.constant = heightValue
        }
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        superview?.removeObserver(self, forKeyPath: keyPathSelector)
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()

        var heightConstraint: NSLayoutConstraint?

        for constraint in constraints {
            if constraint.firstItem as? UIView == self, constraint.firstAttribute == .height, constraint.relation == .equal {
                heightConstraint = constraint
                break
            }
        }

        self.heightConstraint = heightConstraint
        self.heightConstraint?.constant = heightValue

        if let superview = superview {
//            delegate?.pseudoAccessoryView(self, keyboardFrameDidChange: superview.frame)
            superview.addObserver(self, forKeyPath: keyPathSelector, context: nil)
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let superview = superview, object as? UIView == superview, keyPath == keyPathSelector, superview.frame != oldFrame {
            oldFrame = superview.frame
            delegate?.pseudoAccessoryView(self, keyboardFrameDidChange: superview.frame)
        }
    }

    deinit {
        superview?.removeObserver(self, forKeyPath: keyPathSelector)
    }

}
