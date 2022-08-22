import UIKit
import ThemeKit
import SnapKit

class SingleLineFormTextView: UIView, IFormTextView {
    private var textViewFont: UIFont = .body

    private let wrapperView = UIView()
    private let textField = UITextField()
    private let placeholderLabel = UILabel()

    var onChangeHeight: (() -> ())?
    var onChangeText: ((String?) -> ())?
    var onChangeEditing: ((Bool) -> ())?
    var isValidText: ((String) -> Bool)?

    var textFieldInset: UIEdgeInsets = .zero

    init() {
        super.init(frame: .zero)

        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        wrapperView.clipsToBounds = true

        wrapperView.addSubview(textField)
        textField.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
        }

        textField.delegate = self
        textField.tintColor = .themeInputFieldTintColor
        textField.keyboardAppearance = .themeDefault
        textField.textColor = .themeLeah
        textField.font = textViewFont
        textField.backgroundColor = .clear

        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        wrapperView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { maker in
            maker.edges.equalTo(textField)
        }

        placeholderLabel.font = textViewFont
        placeholderLabel.textColor = .themeGray50
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    private func height(text: String, width: CGFloat) -> CGFloat {
         round(textViewFont.lineHeight) + textFieldInset.height
    }

    private func syncPlaceholder() {
        placeholderLabel.isHidden = !((textField.text ?? "").isEmpty)
    }

    @objc private func textFieldDidChange() {
        onChangeText?(textField.text)
        syncPlaceholder()
    }

}

extension SingleLineFormTextView {

    var text: String? {
        get {
            textField.text
        }
        set {
            textField.text = newValue
            syncPlaceholder()
        }
    }

    var textColor: UIColor? {
        get { textField.textColor }
        set { textField.textColor = newValue }
    }

    var font: UIFont? {
        get { textField.font }
        set {
            textViewFont = newValue ?? textViewFont
            textField.font = newValue
            placeholderLabel.font = newValue
        }
    }

    var placeholder: String? {
        get { placeholderLabel.text }
        set { placeholderLabel.text = newValue }
    }

    var isEditable: Bool {
        get { textField.isUserInteractionEnabled }
        set { textField.isUserInteractionEnabled = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }

    var autocapitalizationType: UITextAutocapitalizationType {
        get { textField.autocapitalizationType }
        set { textField.autocapitalizationType = newValue }
    }

    var autocorrectionType: UITextAutocorrectionType {
        get { textField.autocorrectionType }
        set { textField.autocorrectionType = newValue }
    }

    var textViewInset: UIEdgeInsets {
        get { textFieldInset }
        set {
            textFieldInset = newValue

            textField.snp.remakeConstraints { maker in
                maker.top.equalToSuperview().inset(textViewInset.top)
                maker.leading.equalToSuperview().inset(textFieldInset.left)
                maker.trailing.equalToSuperview().inset(textFieldInset.right)
            }
            placeholderLabel.snp.remakeConstraints { maker in
                maker.edges.equalTo(textField)
            }
        }
    }

}

extension SingleLineFormTextView: UITextFieldDelegate {

    public func textField(_ textView: UITextField, shouldChangeCharactersIn range: NSRange, replacementString text: String) -> Bool {
        let newText = ((textView.text ?? "") as NSString).replacingCharacters(in: range, with: text)

        if text.isEmpty || newText.isEmpty {       // allow backspacing in inputView
            return true
        }

        let isValid = isValidText?(newText) ?? true

        if !isValid {
            textView.shakeView()
        }

        return isValid
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        onChangeEditing?(true)
    }

    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        onChangeEditing?(false)
    }

}

extension SingleLineFormTextView {

    func height(containerWidth: CGFloat) -> CGFloat {
        height(text: textField.text ?? "", width: containerWidth)
    }

}
