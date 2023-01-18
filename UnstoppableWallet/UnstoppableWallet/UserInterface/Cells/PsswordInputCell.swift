import UIKit
import ThemeKit
import SnapKit

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

    required init?(coder: NSCoder) {
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

    var onTextSecurityChange: ((Bool) -> ())? {
        get { passwordInputView.onTextSecurityChange }
        set { passwordInputView.onTextSecurityChange = newValue }
    }

    var onChangeText: ((String?) -> ())? {
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
