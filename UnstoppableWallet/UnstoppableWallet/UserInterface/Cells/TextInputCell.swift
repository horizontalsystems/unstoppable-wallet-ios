import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class TextInputCell: UITableViewCell {
    private static let minimalTextHeight: CGFloat = 64

    private let horizontalMargin: CGFloat = .margin16
    private let textViewEdgeInsets = UIEdgeInsets(top: .margin12, left: .margin12, bottom: .margin48, right: .margin12)
    let textViewFont: UIFont = .body
    let textViewTextColor: UIColor = .themeLeah
    private let textViewBorderColor: UIColor = .themeSteel20

    let textView = UITextView()
    private let borderView = UIView()

    private let placeholderLabel = UILabel()

    private let clearButton = SecondaryCircleButton()
    private let qrButton = SecondaryCircleButton()
    private let pasteButton = SecondaryButton()

    var onChangeHeight: (() -> Void)?
    var onChangeText: ((String) -> Void)?
    var onChangeTextViewCaret: ((UITextView) -> Void)?
    var onOpenViewController: ((UIViewController) -> Void)?

    private(set) var textForHeight: String = "" {
        didSet {
            onChangeHeight?()
        }
    }

    private let statPage: StatPage
    private let statEntity: StatEntity

    init(statPage: StatPage, statEntity: StatEntity) {
        self.statPage = statPage
        self.statEntity = statEntity

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(horizontalMargin)
            maker.top.bottom.equalToSuperview()
        }

        textView.keyboardAppearance = .themeDefault
        textView.backgroundColor = .themeLawrence
        textView.layer.cornerRadius = .cornerRadius12
        textView.layer.cornerCurve = .continuous
        textView.textColor = textViewTextColor
        textView.font = textViewFont
        textView.tintColor = .themeJacob
        textView.textContainerInset = textViewEdgeInsets
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no

        textView.delegate = self

        contentView.addSubview(borderView)
        borderView.snp.makeConstraints { maker in
            maker.edges.equalTo(textView)
        }

        borderView.backgroundColor = .clear
        borderView.isUserInteractionEnabled = false
        borderView.layer.cornerRadius = .cornerRadius12
        borderView.layer.cornerCurve = .continuous
        borderView.layer.borderWidth = .heightOneDp
        borderView.layer.borderColor = textViewBorderColor.cgColor

        contentView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(textView).inset(CGFloat.margin16)
            make.top.equalTo(textView).inset(CGFloat.margin12)
        }

        placeholderLabel.numberOfLines = 0
        placeholderLabel.font = .body
        placeholderLabel.textColor = .themeGray50

        let stackView = UIStackView()

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.trailing.equalTo(textView).inset(CGFloat.margin16)
            make.bottom.equalTo(textView).inset(CGFloat.margin16)
        }

        stackView.spacing = .margin8
        stackView.alignment = .center

        stackView.addArrangedSubview(clearButton)
        clearButton.set(image: UIImage(named: "trash_20"))
        clearButton.addTarget(self, action: #selector(onTapClear), for: .touchUpInside)

        stackView.addArrangedSubview(qrButton)
        qrButton.set(image: UIImage(named: "qr_scan_20"))
        qrButton.addTarget(self, action: #selector(onTapQr), for: .touchUpInside)

        stackView.addArrangedSubview(pasteButton)
        pasteButton.set(style: .default)
        pasteButton.setTitle("button.paste".localized, for: .normal)
        pasteButton.addTarget(self, action: #selector(onTapPaste), for: .touchUpInside)

        syncComponents()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    @objc private func onTapClear() {
        set(text: "")
        stat(page: statPage, event: .clear(entity: statEntity))
    }

    @objc private func onTapQr() {
        let scanQrViewController = ScanQrViewController()
        scanQrViewController.didFetch = { [weak self] in
            self?.onScanQr(text: $0)
        }

        onOpenViewController?(scanQrViewController)
    }

    @objc private func onTapPaste() {
        if let string = UIPasteboard.general.string {
            set(text: string)
            stat(page: statPage, event: .paste(entity: statEntity))
        }
    }

    private func onScanQr(text: String) {
        set(text: text)
        stat(page: statPage, event: .scanQr(entity: statEntity))
    }

    private func syncComponents() {
        placeholderLabel.isHidden = !textView.text.isEmpty
        clearButton.isHidden = textView.text.isEmpty
        qrButton.isHidden = !textView.text.isEmpty
        pasteButton.isHidden = !textView.text.isEmpty
    }

    func set(placeholderText: String) {
        placeholderLabel.text = placeholderText
    }

    func set(text: String) {
        textForHeight = text
        textView.text = text
        syncComponents()

        onChangeText?(text)
    }

    func set(cautionType: CautionType?) {
        let borderColor: UIColor

        if let cautionType {
            borderColor = cautionType.borderColor
        } else {
            borderColor = textViewBorderColor
        }

        borderView.layer.borderColor = borderColor.cgColor
    }

    func cellHeight(containerWidth: CGFloat) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalMargin - textViewEdgeInsets.width - 2 * textView.textContainer.lineFragmentPadding
        let textHeight = textForHeight.height(forContainerWidth: textWidth, font: textViewFont)
        return max(Self.minimalTextHeight, textHeight) + textViewEdgeInsets.height
    }
}

extension TextInputCell: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        textForHeight = (textView.text as NSString).replacingCharacters(in: range, with: text)
        return true
    }

    public func textViewDidChange(_ textView: UITextView) {
        syncComponents()
        onChangeTextViewCaret?(textView)
        onChangeText?(textView.text)
    }

    public func textViewDidBeginEditing(_: UITextView) {}

    public func textViewDidEndEditing(_: UITextView) {}
}
