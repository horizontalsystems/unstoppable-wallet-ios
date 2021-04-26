import UIKit
import ThemeKit
import ComponentKit

class ButtonCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin4x

    private let button = ThemeButton()

    private var onTap: (() -> ())?

    var isEnabled: Bool {
        get {
            button.isEnabled
        }
        set {
            button.isEnabled = newValue
        }
    }

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(button)
        makeConstraints()

        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeConstraints(style: ThemeButtonStyle? = nil, compact: Bool = false) {
        let height = ThemeButton.height(style: style)

        button.snp.remakeConstraints { maker in
            if compact {
                maker.centerX.equalToSuperview()
                maker.leading.greaterThanOrEqualToSuperview().inset(CGFloat.margin4x)
            } else {
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            }
            maker.top.equalToSuperview().inset(ButtonCell.verticalPadding)
            maker.height.equalTo(height)
        }

        UIView.performWithoutAnimation {
            layoutIfNeeded()
        }
    }

    @objc private func onTapButton() {
        onTap?()
    }

    var title: String? {
        get { button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
    }

    func bind(style: ThemeButtonStyle, title: String?, compact: Bool = false, onTap: (() -> ())?) {
        makeConstraints(style: style, compact: compact)

        button.apply(style: style)
        button.setTitle(title, for: .normal)
        self.onTap = onTap
    }

    func set(enabled: Bool) {
        button.isEnabled = enabled
    }

}

extension ButtonCell {

    static func height(style: ThemeButtonStyle) -> CGFloat {
        ThemeButton.height(style: style) + 2 * verticalPadding
    }

}
