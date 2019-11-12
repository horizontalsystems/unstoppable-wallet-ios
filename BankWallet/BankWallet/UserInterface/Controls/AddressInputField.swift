import UIKit
import SnapKit

class AddressTextView: UITextView {
    var onPaste: (() -> ())?

    override func paste(_ sender: Any?) {
        onPaste?()
    }

}

class AddressInputField: UIView {
    private let errorFont: UIFont = .appCaption

    private let addressWrapperView = UIView()
    private let addressField = AddressTextView()
    private let placeholderLabel = UILabel()
    private let errorLabel = UILabel()
    private let scanButton = RespondButton()
    private let scanButtonIcon = UIImageView()
    private let deleteButton = RespondButton()
    private let deleteButtonIcon = UIImageView()
    private let pasteButton = RespondButton()
    private let copyButton = RespondButton()
    private let copyButtonIcon = UIImageView()
    private let textViewCenterFixOffset: CGFloat = 1

    private let placeholder: String?
    private let numberOfLines: Int
    private let showQrButton: Bool
    private let canEdit: Bool
    private let rightButtonMode: RightButtonMode

    init(frame: CGRect, placeholder: String?, numberOfLines: Int = 1, showQrButton: Bool, canEdit: Bool, lineBreakMode: NSLineBreakMode, rightButtonMode: RightButtonMode = .delete) {
        self.placeholder = placeholder
        self.numberOfLines = numberOfLines
        self.showQrButton = showQrButton
        self.canEdit = canEdit
        self.rightButtonMode = rightButtonMode
        super.init(frame: frame)

        addSubview(addressWrapperView)
        addressWrapperView.addSubview(addressField)
        addressWrapperView.addSubview(errorLabel)
        addressField.addSubview(placeholderLabel)
        addSubview(scanButton)
        scanButton.addSubview(scanButtonIcon)
        addSubview(deleteButton)
        deleteButton.addSubview(deleteButtonIcon)
        addSubview(copyButton)
        copyButton.addSubview(copyButtonIcon)
        addSubview(pasteButton)

        layer.cornerRadius = SendTheme.holderCornerRadius
        layer.borderWidth = SendTheme.holderBorderWidth
        layer.borderColor = SendTheme.holderBorderColor.cgColor
        backgroundColor = SendTheme.holderBackground

        addressField.delegate = self
        addressField.tintColor = AppTheme.textFieldTintColor
        addressField.keyboardAppearance = App.theme.keyboardAppearance
        addressField.autocapitalizationType = .none
        addressField.isUserInteractionEnabled = canEdit
        addressField.textContainer.maximumNumberOfLines = numberOfLines
        addressField.textColor = SendTheme.addressColor
        addressField.font = SendTheme.addressFont
        addressField.textContainer.lineBreakMode = lineBreakMode
        addressField.textContainer.lineFragmentPadding = 0
        addressField.textContainerInset = .zero
        addressField.backgroundColor = .clear
        addressField.onPaste = { [weak self] in
            self?.onPaste?()
        }
        placeholderLabel.textColor = SendTheme.addressHintColor
        placeholderLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
        placeholderLabel.text = placeholder

        errorLabel.font = errorFont
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.numberOfLines = 0

        pasteButton.borderWidth = 1 / UIScreen.main.scale
        pasteButton.borderColor = SendTheme.buttonBorderColor
        pasteButton.cornerRadius = SendTheme.buttonCornerRadius
        pasteButton.backgrounds = SendTheme.buttonBackground
        pasteButton.textColors = [.active: SendTheme.buttonIconColor, .selected: SendTheme.buttonIconColor]
        pasteButton.titleLabel.text = "button.paste".localized
        pasteButton.titleLabel.font = .appSubhead1
        pasteButton.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        pasteButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(SendTheme.sendSmallButtonMargin)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(SendTheme.buttonSize)
        }
        pasteButton.wrapperView.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.smallMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.smallMargin)
        }

        scanButton.isHidden = !showQrButton
        scanButton.borderWidth = 1 / UIScreen.main.scale
        scanButton.borderColor = SendTheme.buttonBorderColor
        scanButton.cornerRadius = SendTheme.buttonCornerRadius
        scanButton.backgrounds = SendTheme.buttonBackground
        scanButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(pasteButton.snp.leading).offset(-SendTheme.smallMargin)
            maker.centerY.equalTo(pasteButton.snp.centerY)
            maker.height.equalTo(SendTheme.buttonSize)
            maker.width.equalTo(SendTheme.scanButtonWidth)
        }

        scanButtonIcon.image = UIImage(named: "Send Scan Icon")?.tinted(with: SendTheme.buttonIconColor)
        scanButtonIcon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        deleteButton.borderWidth = 1 / UIScreen.main.scale
        deleteButton.borderColor = SendTheme.buttonBorderColor
        deleteButton.cornerRadius = SendTheme.buttonCornerRadius
        deleteButton.backgrounds = SendTheme.buttonBackground
        deleteButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(self.pasteButton)
            maker.centerY.equalTo(pasteButton.snp.centerY)
            maker.size.equalTo(SendTheme.buttonSize)
        }

        deleteButtonIcon.image = UIImage(named: "Send Delete Icon")?.tinted(with: SendTheme.buttonIconColor)
        deleteButtonIcon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        copyButton.borderWidth = 1 / UIScreen.main.scale
        copyButton.borderColor = SendTheme.buttonBorderColor
        copyButton.cornerRadius = SendTheme.buttonCornerRadius
        copyButton.backgrounds = SendTheme.buttonBackground
        copyButton.snp.makeConstraints { maker in
            maker.edges.equalTo(deleteButton)
        }

        copyButtonIcon.image = UIImage(named: "Address Field Copy Icon")?.tinted(with: SendTheme.buttonIconColor)
        copyButtonIcon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        bind(address: nil, error: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var onPaste: (() -> ())? {
        didSet {
            pasteButton.onTap = onPaste
        }
    }
    var onScan: (() -> ())? {
        didSet {
            scanButton.onTap = onScan
        }
    }
    var onDelete: (() -> ())? {
        didSet {
            deleteButton.onTap = onDelete
        }
    }
    var onCopy: (() -> ())? {
        didSet {
            copyButton.onTap = onCopy
        }
    }
    var onTextChange: ((String?) -> ())?

    func bind(address: String?, error: Error?) {
        if let address = address, !address.isEmpty {
            placeholderLabel.isHidden = true
            addressField.text = address
            pasteButton.isHidden = true
            scanButton.isHidden = true
            deleteButton.isHidden = rightButtonMode == .delete ? false : true
            copyButton.isHidden = rightButtonMode == .copy ? false : true

            addressWrapperView.snp.remakeConstraints { maker in
                maker.top.bottom.equalToSuperview()
                maker.leading.equalToSuperview().offset(SendTheme.mediumMargin)
                maker.trailing.equalTo(deleteButton.snp.leading).offset(-SendTheme.mediumMargin)
                maker.centerY.equalTo(deleteButton.snp.centerY).offset(textViewCenterFixOffset)
                maker.height.greaterThanOrEqualTo(SendTheme.addressHolderHeight)
            }
        } else {
            placeholderLabel.isHidden = false
            addressField.text = nil
            pasteButton.isHidden = false
            scanButton.isHidden = false || !showQrButton
            deleteButton.isHidden = true
            copyButton.isHidden = true

            addressWrapperView.snp.remakeConstraints { maker in
                maker.top.bottom.equalToSuperview()
                maker.leading.equalToSuperview().offset(SendTheme.mediumMargin)
                maker.centerY.equalTo(pasteButton.snp.centerY).offset(textViewCenterFixOffset)
                maker.height.greaterThanOrEqualTo(SendTheme.addressHolderHeight)

                if showQrButton {
                    maker.trailing.equalTo(scanButton.snp.leading).offset(-SendTheme.mediumMargin)
                } else {
                    maker.trailing.equalTo(pasteButton.snp.leading).offset(-SendTheme.mediumMargin)
                }
            }
        }
        layoutSubviews()

        if let errorDescription = error?.localizedDescription {
            errorLabel.isHidden = false
            errorLabel.text = errorDescription

            addressField.snp.remakeConstraints { maker in
                maker.top.equalToSuperview().offset(CGFloat.margin3x)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(SendTheme.addressTextViewLineHeight * numberOfLines)
            }
            errorLabel.snp.remakeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(addressField.snp.bottom).offset(CGFloat.margin1x)
                maker.height.equalTo(errorFieldHeight(text: errorDescription))
                maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
            }
        } else {
            errorLabel.isHidden = true
            errorLabel.snp.removeConstraints()
            addressField.snp.remakeConstraints { maker in
                maker.leading.trailing.centerY.equalToSuperview()
                maker.height.equalTo(SendTheme.addressTextViewLineHeight * numberOfLines)
            }
        }
    }

    private func errorFieldHeight(text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: addressWrapperView.bounds.width, font: errorFont)
        return textHeight
    }

    override func becomeFirstResponder() -> Bool {
        addressField.becomeFirstResponder()
    }

}

extension AddressInputField: UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        onTextChange?(textView.text)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.contains(words: "\n") {
            return false
        }
        return true
    }

}

extension AddressInputField {
    public enum RightButtonMode {
        case delete
        case copy
    }
}
