import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class InputSecondaryCircleButtonWrapperView: UIView, ISizeAwareView {
    let button = SecondaryCircleButton()

    var onTapButton: (() -> Void)?

    init() {
        super.init(frame: .zero)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        onTapButton?()
    }

    func width(containerWidth _: CGFloat) -> CGFloat {
        SecondaryCircleButton.size
    }
}
