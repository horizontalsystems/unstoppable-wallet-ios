import UIKit
import ThemeKit
import SnapKit

class TextFieldStackView: UIView {
    private let stackView = UIStackView()
    private let textField = UITextField()

    var onChangeText: ((String?) -> ())?

    init() {
        super.init(frame: .zero)

        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardAppearance = .themeDefault
        textField.tintColor = .themeInputFieldTintColor
        textField.font = .body
        textField.textColor = .themeOz
        textField.clearButtonMode = .whileEditing

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
