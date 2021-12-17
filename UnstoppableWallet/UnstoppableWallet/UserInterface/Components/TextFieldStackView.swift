import UIKit
import ThemeKit
import SnapKit

class TextFieldStackView: UIView {
    private let stackView = UIStackView()
    private let textField = UITextField()

    var onChangeText: ((String?) -> ())?
    var onReturn: (() -> ())?
    var onSpaceKey: (() -> Bool)?
    var isValidText: ((String?) -> Bool)?

    init() {
        super.init(frame: .zero)

        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .none
        textField.keyboardAppearance = .themeDefault
        textField.tintColor = .themeInputFieldTintColor
        textField.font = .body
        textField.textColor = .themeOz
        textField.clearButtonMode = .whileEditing

        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.spacing = .margin8
        stackView.alignment = .fill
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: .margin12, bottom: 0, right: .margin8)
        stackView.isLayoutMarginsRelativeArrangement = true

        stackView.addArrangedSubview(textField)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @objc private func textFieldDidChange() {
        onChangeText?(textField.text)
    }

}

extension TextFieldStackView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isValid = isValidText?(string) ?? true

        if !isValid {
            shakeView()
        }

        return isValid
    }

}

extension TextFieldStackView {

    var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }

    var autocapitalizationType: UITextAutocapitalizationType {
        get { textField.autocapitalizationType }
        set { textField.autocapitalizationType = newValue }
    }

    var returnKeyType: UIReturnKeyType {
        get { textField.returnKeyType }
        set { textField.returnKeyType = newValue }
    }

    var isSecureTextEntry: Bool {
        get { textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }

    func prependSubview(_ view: UIView, customSpacing: CGFloat? = nil) {
        stackView.insertArrangedSubview(view, at: 0)

        if let customSpacing = customSpacing {
            stackView.setCustomSpacing(customSpacing, after: view)
        }
    }

    func appendSubview(_ view: UIView) {
        stackView.addArrangedSubview(view)
    }

}
