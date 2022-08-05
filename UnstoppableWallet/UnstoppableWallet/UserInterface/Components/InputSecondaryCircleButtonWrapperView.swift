import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class InputSecondaryCircleButtonWrapperView: UIView, ISizeAwareView {
    let button = SecondaryCircleButton()

    var onTapButton: (() -> ())?

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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        onTapButton?()
    }

    func width(containerWidth: CGFloat) -> CGFloat {
        SecondaryCircleButton.size
    }

}
