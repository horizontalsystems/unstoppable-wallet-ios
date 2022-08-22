import UIKit
import ThemeKit
import SnapKit

protocol IFormTextView: UIView {
    var onChangeHeight: (() -> ())? { get set }
    var onChangeText: ((String?) -> ())? { get set }
    var onChangeEditing: ((Bool) -> ())? { get set }
    var isValidText: ((String) -> Bool)? { get set }

    func becomeFirstResponder() -> Bool

    var text: String? { get set }
    var textColor: UIColor? { get set }
    var font: UIFont? { get set }
    var placeholder: String? { get set }
    var isEditable: Bool { get set }
    var keyboardType: UIKeyboardType { get set }
    var autocapitalizationType: UITextAutocapitalizationType { get set }
    var autocorrectionType: UITextAutocorrectionType { get set }
    var textViewInset: UIEdgeInsets { get set }

    func height(containerWidth: CGFloat) -> CGFloat
}

class FormTextView: UIView, IFormTextView {
    private var textViewFont: UIFont = .body

    private let textView = UITextView()
    private let placeholderLabel = UILabel()

    var onChangeHeight: (() -> ())?
    var onChangeText: ((String?) -> ())?
    var onChangeEditing: ((Bool) -> ())?
    var isValidText: ((String) -> Bool)?

    init() {
        super.init(frame: .zero)

        addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        textView.delegate = self
        textView.tintColor = .themeInputFieldTintColor
        textView.keyboardAppearance = .themeDefault
        textView.textColor = .themeLeah
        textView.font = textViewFont
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false

        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        placeholderLabel.font = textViewFont
        placeholderLabel.textColor = .themeGray50
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        notifyHeightChangedIfRequired()
    }

    override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    private func height(text: String, width: CGFloat) -> CGFloat {
        let textWidth = width - textView.textContainerInset.width - 2 * textView.textContainer.lineFragmentPadding
        var textHeight: CGFloat

        if text.isEmpty {
            textHeight = ceil(textViewFont.lineHeight)
        } else {
            textHeight = text.height(forContainerWidth: textWidth, font: textViewFont)
        }

        return textHeight + textView.textContainerInset.height
    }

    private func notifyHeightChangedIfRequired() {
        if height != height(containerWidth: width) {
            onChangeHeight?()
        }
    }

    private func syncPlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

}

extension FormTextView {

    var text: String? {
        get {
            textView.text
        }
        set {
            textView.text = newValue
            syncPlaceholder()
        }
    }

    var textColor: UIColor? {
        get { textView.textColor }
        set { textView.textColor = newValue }
    }

    var font: UIFont? {
        get { textView.font }
        set {
            textViewFont = newValue ?? textViewFont
            textView.font = newValue
            placeholderLabel.font = newValue
        }
    }

    var placeholder: String? {
        get { placeholderLabel.text }
        set { placeholderLabel.text = newValue }
    }

    var isEditable: Bool {
        get { textView.isUserInteractionEnabled }
        set { textView.isUserInteractionEnabled = newValue }
    }

    var maximumNumberOfLines: Int {
        get { textView.textContainer.maximumNumberOfLines }
        set { textView.textContainer.maximumNumberOfLines = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { textView.keyboardType }
        set { textView.keyboardType = newValue }
    }

    var autocapitalizationType: UITextAutocapitalizationType {
        get { textView.autocapitalizationType }
        set { textView.autocapitalizationType = newValue }
    }

    var autocorrectionType: UITextAutocorrectionType {
        get { textView.autocorrectionType }
        set { textView.autocorrectionType = newValue }
    }

    var textViewInset: UIEdgeInsets {
        get {
            textView.textContainerInset
        }
        set {
            textView.textContainerInset = newValue
            placeholderLabel.snp.remakeConstraints { maker in
                maker.edges.equalToSuperview().inset(newValue)
            }
        }
    }

}

extension FormTextView: UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        onChangeText?(textView.text)
        syncPlaceholder()
        notifyHeightChangedIfRequired()
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)

        if text.isEmpty || newText.isEmpty {       // allow backspacing in inputView
            return true
        }

        let isValid = isValidText?(newText) ?? true

        if !isValid {
            textView.shakeView()
        }

        return isValid
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        onChangeEditing?(true)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        onChangeEditing?(false)
    }

}

extension FormTextView {

    func height(containerWidth: CGFloat) -> CGFloat {
        height(text: textView.text, width: containerWidth)
    }

}
