import UIKit
import ThemeKit
import SnapKit

class InputPrefixWrapperView: UIView, ISizeAwareView {
    private let leadingMargin: CGFloat = .margin4

    let label = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(leadingMargin)
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        label.font = .body
        label.textColor = .themeOz
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func width(containerWidth: CGFloat) -> CGFloat {
        guard let text = label.text else {
            return leadingMargin
        }

        return text.size(containerWidth: containerWidth, font: label.font).width + leadingMargin
    }

}

extension InputPrefixWrapperView {

    var textColor: UIColor? {
        get { label.textColor }
        set { label.textColor = newValue }
    }

}
