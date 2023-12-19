import UIKit

class ActionSheetTapView: UIView {
    var handleTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(gestureRecognizer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        handleTap?()
    }
}
