import UIKit
import RxSwift
import ThemeKit

protocol InputFieldDelegate: AnyObject {
    func onChange(_ text: String?)
    func isValid(_ text: String) -> Bool
}

enum ButtonVisibleState {
    case onEmpty
    case onFilled
    case always
}

class InputFieldButtonItem {
    let style: ThemeButtonStyle

    let title: String?
    let icon: UIImage?

    let visible: ButtonVisibleState
    let action: (() -> ())?

    init(style: ThemeButtonStyle, title: String? = nil, icon: UIImage? = nil, visible: ButtonVisibleState, action: (() -> ())?) {
        self.style = style
        self.title = title
        self.icon = icon
        self.visible = visible
        self.action = action
    }

}

class InputFieldStackView: UIView {
    static private let errorTopMargin: CGFloat = .margin1x
    static private let textViewMargin: CGFloat = .margin1x
    static private let textViewFont: UIFont = .body

    private let textViewWrapper = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()

    private let stackView = UIStackView()
    private let errorLabel = UILabel()

    private var buttonItems = [InputFieldButtonItem]()

    weak var delegate: InputFieldDelegate?

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

    init() {
        super.init(frame: .zero)

        backgroundColor = .themeLawrence

        layer.cornerRadius = .cornerRadius2x
        layer.borderWidth = CGFloat.heightOnePixel
        layer.borderColor = UIColor.themeSteel20.cgColor

        textViewWrapper.addSubview(textView)
        textViewWrapper.snp.makeConstraints { maker in
            maker.height.equalTo(height(text: nil))
        }

        textView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(Self.textViewMargin)
        }

        textView.delegate = self
        textView.tintColor = .themeInputFieldTintColor
        textView.keyboardAppearance = .themeDefault
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


        stackView.addArrangedSubview(textViewWrapper)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin2x)
        }

        stackView.spacing = .margin2x
        stackView.alignment = .center

        addSubview(errorLabel)

        errorLabel.font = .caption
        errorLabel.textColor = .themeLucian
        errorLabel.numberOfLines = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func buttonTapped(_ button: UIButton) {
        guard button.tag < buttonItems.count else {
            return
        }

        buttonItems[button.tag].action?()
    }

    private func textViewDidChange() {
        stackView
                .arrangedSubviews
                .compactMap { $0 as? ThemeButton }
                .forEach { updateVisibleState(button: $0, isEmptyText: textView.text.isEmpty) }

        self.layoutIfNeeded()
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
        guard let text = text, maximumNumberOfLines == 0 else {
            return CGFloat(maximumNumberOfLines) * Self.textViewFont.lineHeight + 2 * Self.textViewMargin
        }
        let containerWidth = textView.bounds.width - 2 * textView.textContainer.lineFragmentPadding
        let textHeight = text.height(forContainerWidth: containerWidth, font: Self.textViewFont)
        return textHeight + 2 * Self.textViewMargin
    }

    private func updateTextViewConstraints(for text: String, animated: Bool = false) {
        textViewWrapper.snp.updateConstraints { maker in
            maker.height.equalTo(height(text: text))
        }

        if animated {
            UIView.animate(withDuration: .themeAnimationDuration) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }

}

extension InputFieldStackView {

    func set(placeholder: String, color: UIColor = UIColor.themeGray50) {
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = color
    }

    func add(item: InputFieldButtonItem) {
        let button = ThemeButton().apply(style: item.style)

        button.setTitle(item.title, for: .normal)
        button.apply(secondaryIconImage: item.icon)
        button.tag = buttonItems.count
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        buttonItems.append(item)
        stackView.addArrangedSubview(button)
        updateVisibleState(button: button, isEmptyText: textView.text.isEmpty)
    }

    func bind(error: String?) {
        if let error = error {
            errorLabel.isHidden = false
            errorLabel.text = error

            stackView.snp.remakeConstraints { maker in
                maker.top.trailing.equalToSuperview().inset(CGFloat.margin2x)
                maker.leading.equalToSuperview().inset(CGFloat.margin3x)
            }
            errorLabel.snp.remakeConstraints { maker in
                maker.top.equalTo(stackView.snp.bottom).offset(Self.errorTopMargin)
                maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin3x)
            }
        } else {
            errorLabel.isHidden = true
            errorLabel.snp.removeConstraints()
            stackView.snp.remakeConstraints { maker in
                maker.top.trailing.bottom.equalToSuperview().inset(CGFloat.margin2x)
                maker.leading.equalToSuperview().inset(CGFloat.margin3x)
            }
        }
    }

}

extension InputFieldStackView: UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        textViewDidChange()
        updateTextViewConstraints(for: textView.text)

        placeholderLabel.isHidden = !textView.text.isEmpty
        delegate?.onChange(textView.text)
    }

    private func validate(text: String) -> Bool {
        let isValid = delegate?.isValid(text) ?? true
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
