import UIKit

class ActionSheetTapView: UIView {
    var handleTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(gestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        handleTap?()
    }

}
