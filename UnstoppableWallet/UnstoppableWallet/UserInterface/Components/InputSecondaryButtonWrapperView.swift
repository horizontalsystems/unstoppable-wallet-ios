import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class InputSecondaryButtonWrapperView: UIView, ISizeAwareView {
    let button = SecondaryButton()

    var onTapButton: (() -> ())?

    init(style: SecondaryButton.Style) {
        super.init(frame: .zero)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        button.set(style: style)
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
        SecondaryButton.width(title: button.title(for: .normal) ?? "")
    }

}
