import UIKit

protocol RespondViewDelegate: class {
    func touchBegan()
    func touchEnd()
}

public class RespondView: UIView {
    weak var delegate: RespondViewDelegate?

    var handleTouch: (() -> ())?

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchBegan()
        super.touchesBegan(touches, with: event)
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchEnd()
        handleTouch?()

        super.touchesEnded(touches, with: event)
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchEnd()

        super.touchesCancelled(touches, with: event)
    }

}
