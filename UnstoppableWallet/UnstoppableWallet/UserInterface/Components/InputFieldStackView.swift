import UIKit
import RxSwift
import ThemeKit

enum ButtonVisibleState {
    case onEmpty
    case onFilled
    case always
}

class InputFieldButtonItem {
    let title: String?
    let icon: UIImage?

    let visible: ButtonVisibleState
    let action: (() -> ())?

    init(title: String? = nil, icon: UIImage? = nil, visible: ButtonVisibleState, action: (() -> ())? = nil) {
        self.title = title
        self.icon = icon
        self.visible = visible
        self.action = action
    }

}

class InputFieldStackView: UIStackView {
    static private let textViewMargin: CGFloat = .margin1x
    static private let textViewFont: UIFont = .body
    static private let itemSpacing: CGFloat = .margin2x

    private let textViewWrapper = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()

    private var lastHeight = CGFloat.zero
    private var buttonItems = [InputFieldButtonItem]()

    var text: String {
        get {
            textView.text
        }
        set {
            textView.text = newValue
            updateUI()
        }
    }

    var onChangeText: ((String) -> ())?
    var isValidText: ((String) -> Bool)?
    var onChangeHeight: ((CGFloat) -> ())?

    var canEdit: Bool {
        get {
            textView.isUserInteractionEnabled
        }
        set {
            textView.isUserInteractionEnabled = newValue
        }
    }

    var maximumNumberOfLines: Int = 1 {
        didSet {
            textView.textContainer.maximumNumberOfLines = maximumNumberOfLines
        }
    }

    var decimalKeyboard: Bool = true {
        didSet {
            if decimalKeyboard {
                textView.keyboardType = .decimalPad
            }
        }
    }

    var keyboardAppearance: UIKeyboardAppearance = .themeDefault {
        didSet {
            textView.keyboardAppearance = keyboardAppearance
        }
    }

    init() {
        super.init(frame: .zero)

        textViewWrapper.snp.makeConstraints { maker in
            maker.height.equalTo(height(text: nil))
        }

        textViewWrapper.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(Self.textViewMargin)
        }

        textView.delegate = self
        textView.tintColor = .themeInputFieldTintColor
        textView.keyboardAppearance = keyboardAppearance
        textView.autocapitalizationType = .none
        textView.textContainer.maximumNumberOfLines = maximumNumberOfLines
        textView.textColor = .themeOz
        textView.font = Self.textViewFont
        textView.textContainer.lineBreakMode = .byTruncatingMiddle
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        textView.autocorrectionType = .no
        textView.isScrollEnabled = false

        textViewWrapper.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { maker in
            maker.edges.equalTo(textView)
        }

        placeholderLabel.textColor = .themeGray50

        addArrangedSubview(textViewWrapper)

        spacing = Self.itemSpacing
        alignment = .center
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func buttonTapped(_ button: UIButton) {
        guard button.tag < buttonItems.count else {
            return
        }

        buttonItems[button.tag].action?()
    }

    private func updateUI() {
        textViewDidChange()
        updateTextViewConstraints(for: textView.text)

        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    private func textViewDidChange() {
        arrangedSubviews
                .compactMap { $0 as? ThemeButton }
                .forEach { updateVisibleState(button: $0, isEmptyText: textView.text.isEmpty) }

        layoutIfNeeded()
    }

    private func updateVisibleState(button: ThemeButton, isEmptyText: Bool) {
        guard button.tag < buttonItems.count else {
            return
        }

        switch buttonItems[button.tag].visible {
        case .onEmpty: button.isHidden = !isEmptyText
        case .onFilled: button.isHidden = isEmptyText
        case .always: button.isHidden = false
        }
    }

    private func height(text: String?) -> CGFloat {
        guard let text = text else {
            return Self.textViewFont.lineHeight + 2 * Self.textViewMargin
        }

        let containerWidth = textView.bounds.width - 2 * textView.textContainer.lineFragmentPadding
        var textHeight = text.height(forContainerWidth: containerWidth, font: Self.textViewFont)

        if maximumNumberOfLines > 0 {
            textHeight = min(textHeight, CGFloat(maximumNumberOfLines) * ceil(Self.textViewFont.lineHeight))
        }

        return textHeight + 2 * Self.textViewMargin
    }

    private func updateTextViewConstraints(for text: String, animated: Bool = false) {
        let newHeight = height(text: text)

        guard lastHeight != newHeight else {
            return
        }
        lastHeight = newHeight

        textViewWrapper.snp.updateConstraints { maker in
            maker.height.equalTo(newHeight)
        }

        if animated {
            UIView.animate(withDuration: .themeAnimationDuration) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }

        onChangeHeight?(newHeight)
    }

}

extension InputFieldStackView {

    override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    func set(placeholder: String, color: UIColor = UIColor.themeGray50) {
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = color
    }

    func set(text: String?) {
        textView.text = text
        textViewDidChange()
        updateTextViewConstraints(for: textView.text)

        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    func append(view: UIView) {
        addArrangedSubview(view)
    }

    func prepend(view: UIView) {
        insertArrangedSubview(view, at: 0)
    }

    func append(items: [InputFieldButtonItem]) {
        items.forEach { append(item: $0) }
    }

    func append(item: InputFieldButtonItem) {
        let button = ThemeButton()
        if item.icon != nil {
            button.apply(style: .secondaryIcon)
        } else {
            button.apply(style: .secondaryDefault)
        }

        button.setTitle(item.title, for: .normal)
        button.apply(secondaryIconImage: item.icon)
        button.tag = buttonItems.count
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        buttonItems.append(item)
        addArrangedSubview(button)
        updateVisibleState(button: button, isEmptyText: textView.text.isEmpty)
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        InputFieldStackView.height(containerWidth: containerWidth, text: text, buttonItems: buttonItems, maximumNumberOfLines: maximumNumberOfLines)
    }

}

extension InputFieldStackView: UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        updateUI()
        onChangeText?(textView.text)
    }

    private func validate(text: String) -> Bool {
        let isValid = isValidText?(text) ?? true
        if !isValid {
            textView.shakeView()
        }
        return isValid
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)

        if text.isEmpty || newText.isEmpty {       // allow backspacing in inputView
            return true
        }

        return validate(text: newText)
    }

}

extension InputFieldStackView {

    static func height(containerWidth: CGFloat, text: String, buttonItems: [InputFieldButtonItem], maximumNumberOfLines: Int) -> CGFloat {
        let visibleState: ButtonVisibleState = text.isEmpty ? ButtonVisibleState.onEmpty : .onFilled
        let showedButtons = buttonItems.filter { $0.visible == visibleState || $0.visible == .always }

        var buttonsWidth: CGFloat = 0

        showedButtons.forEach { item in
            let style: ThemeButtonStyle = item.icon != nil ? .secondaryIcon : .secondaryDefault
            let buttonSize = ThemeButton.size(containerWidth: CGFloat.greatestFiniteMagnitude, text: item.title, icon: item.icon, style: style)
            buttonsWidth += buttonSize.width
        }

        if showedButtons.count > 0 {
            buttonsWidth += CGFloat(showedButtons.count) * Self.itemSpacing
        }

        let textWidth = containerWidth - buttonsWidth - 2 * Self.textViewMargin

        var textHeight = text.height(forContainerWidth: textWidth, font: Self.textViewFont)

        if maximumNumberOfLines > 0 {
            let linesHeight = CGFloat(maximumNumberOfLines) * ceil(Self.textViewFont.lineHeight)
            textHeight = min(textHeight, linesHeight)
        }

        return textHeight + 2 * Self.textViewMargin
    }

}
