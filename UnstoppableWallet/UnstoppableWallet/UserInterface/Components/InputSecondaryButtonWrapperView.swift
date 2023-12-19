import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class InputSecondaryButtonWrapperView: UIView, ISizeAwareView {
    private let style: SecondaryButton.Style
    let button = SecondaryButton()

    var onTapButton: (() -> Void)?

    init(style: SecondaryButton.Style) {
        self.style = style

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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        onTapButton?()
    }

    func width(containerWidth _: CGFloat) -> CGFloat {
        SecondaryButton.width(title: button.title(for: .normal) ?? "", style: style, hasImage: false)
    }
}
