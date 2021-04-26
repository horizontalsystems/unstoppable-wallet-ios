import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class InputButtonWrapperView: UIView, ISizeAwareView {
    private let style: ThemeButtonStyle
    let button = ThemeButton()

    var onTapButton: (() -> ())?

    init(style: ThemeButtonStyle) {
        self.style = style

        super.init(frame: .zero)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        button.apply(style: style)
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
        ThemeButton.size(containerWidth: containerWidth, text: button.title(for: .normal), icon: button.image(for: .normal), style: style).width
    }

}
