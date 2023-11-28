import SnapKit
import ThemeKit
import UIKit

class PasswordInputCell: UITableViewCell {
    private let passwordInputView = PasswordInputView()

    init() {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(passwordInputView)
        passwordInputView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PasswordInputCell {
    var inputPlaceholder: String? {
        get { passwordInputView.inputPlaceholder }
        set { passwordInputView.inputPlaceholder = newValue }
    }

    var inputText: String? {
        get { passwordInputView.inputText }
        set { passwordInputView.inputText = newValue }
    }

    var onTextSecurityChange: ((Bool) -> Void)? {
        get { passwordInputView.onTextSecurityChange }
        set { passwordInputView.onTextSecurityChange = newValue }
    }

    var onChangeText: ((String?) -> Void)? {
        get { passwordInputView.onChangeText }
        set { passwordInputView.onChangeText = newValue }
    }

    var isValidText: ((String) -> Bool)? {
        get { passwordInputView.isValidText }
        set { passwordInputView.isValidText = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        passwordInputView.height(containerWidth: containerWidth)
    }

    func set(cautionType: CautionType?) {
        passwordInputView.set(cautionType: cautionType)
    }

    func set(textSecure: Bool) {
        passwordInputView.set(textSecure: textSecure)
    }
}
