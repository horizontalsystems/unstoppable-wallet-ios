import UIKit
import ThemeKit
import SnapKit

class FormTextView: UIView {
    private let textViewFont: UIFont = .body

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
        textView.autocapitalizationType = .none
        textView.textColor = .themeOz
        textView.font = textViewFont
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.autocorrectionType = .no
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
