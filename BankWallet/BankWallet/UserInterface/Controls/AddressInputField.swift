import UIKit
import SnapKit

class AddressTextView: UITextView {
    var onPaste: (() -> ())?

    override func paste(_ sender: Any?) {
        onPaste?()
    }

}

class AddressInputField: UIView {
    private let errorFont: UIFont = .caption
    private let addressFieldFont: UIFont = .body
    private let textViewCenterFixOffset: CGFloat = 1

    private let addressWrapperView = UIView()
    private let addressField = AddressTextView()
    private let placeholderLabel = UILabel()
    private let errorLabel = UILabel()
    private let scanButton = UIButton.appSecondary
    private let deleteButton = UIButton.appSecondary
    private let pasteButton = UIButton.appSecondary
    private let copyButton = UIButton.appSecondary

    private let placeholder: String?
    private let numberOfLines: Int
    private let showQrButton: Bool
    private let canEdit: Bool
    private let rightButtonMode: RightButtonMode

    var onPaste: (() -> ())?
    var onScan: (() -> ())?
    var onDelete: (() -> ())?
    var onCopy: (() -> ())?
    var onTextChange: ((String?) -> ())?

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
        addSubview(deleteButton)
        addSubview(copyButton)
        addSubview(pasteButton)

        layer.cornerRadius = CGFloat.cornerRadius2x
        layer.borderWidth = 1
        layer.borderColor = UIColor.themeSteel20.cgColor
        backgroundColor = .themeLawrence

        addressField.delegate = self
        addressField.tintColor = .themeInputFieldTintColor
        addressField.keyboardAppearance = .themeDefault
        addressField.autocapitalizationType = .none
        addressField.isUserInteractionEnabled = canEdit
        addressField.textContainer.maximumNumberOfLines = numberOfLines
        addressField.textColor = .themeOz

        addressField.font = addressFieldFont
        addressField.textContainer.lineBreakMode = lineBreakMode
        addressField.textContainer.lineFragmentPadding = 0
        addressField.textContainerInset = .zero
        addressField.backgroundColor = .clear
        addressField.autocorrectionType = .no
        addressField.onPaste = { [weak self] in
            self?.onPaste?()
        }
        placeholderLabel.textColor = .themeGray50
        placeholderLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
        placeholderLabel.text = placeholder

        errorLabel.font = errorFont
        errorLabel.textColor = .themeLucian
        errorLabel.numberOfLines = 0

        pasteButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(6)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButtonSecondary)
        }

        pasteButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        pasteButton.setTitle("button.paste".localized, for: .normal)
        pasteButton.addTarget(self, action: #selector(onTapPaste), for: .touchUpInside)

        scanButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(pasteButton.snp.leading).offset(-CGFloat.margin2x)
            maker.centerY.equalTo(pasteButton.snp.centerY)
            maker.height.equalTo(CGFloat.heightButtonSecondary)
            maker.width.equalTo(36)
        }

        scanButton.isHidden = !showQrButton
        scanButton.setImage(UIImage(named: "Send Scan Icon")?.tinted(with: .themeOz), for: .normal)
        scanButton.addTarget(self, action: #selector(onTapScan), for: .touchUpInside)

        deleteButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(self.pasteButton)
            maker.centerY.equalTo(pasteButton.snp.centerY)
            maker.size.equalTo(CGFloat.heightButtonSecondary)
        }

        deleteButton.setImage(UIImage(named: "Send Delete Icon")?.tinted(with: .themeOz), for: .normal)
        deleteButton.addTarget(self, action: #selector(onTapDelete), for: .touchUpInside)

        copyButton.snp.makeConstraints { maker in
            maker.edges.equalTo(deleteButton)
        }

        copyButton.setImage(UIImage(named: "Address Field Copy Icon")?.tinted(with: .themeOz), for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        bind(address: nil, error: nil)
    }

    @objc private func onTapPaste() {
        onPaste?()
    }

    @objc private func onTapScan() {
        onScan?()
    }

    @objc private func onTapDelete() {
        onDelete?()
    }

    @objc private func onTapCopy() {
        onCopy?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
                maker.leading.equalToSuperview().inset(CGFloat.margin3x)
                maker.trailing.equalTo(deleteButton.snp.leading).offset(-CGFloat.margin3x)
                maker.centerY.equalTo(deleteButton.snp.centerY)
                maker.height.greaterThanOrEqualTo(44)
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
                maker.leading.equalToSuperview().offset(CGFloat.margin3x)
                maker.centerY.equalTo(pasteButton.snp.centerY)
                maker.height.greaterThanOrEqualTo(44)

                if showQrButton {
                    maker.trailing.equalTo(scanButton.snp.leading).offset(-CGFloat.margin3x)
                } else {
                    maker.trailing.equalTo(pasteButton.snp.leading).offset(-CGFloat.margin3x)
                }
            }
        }
        layoutSubviews()
        let height = ceil(addressFieldFont.lineHeight) * CGFloat(numberOfLines)

        if let error = error {
            errorLabel.isHidden = false
            errorLabel.text = error.localizedDescription
            addressField.snp.remakeConstraints { maker in
                maker.top.equalToSuperview().offset(CGFloat.margin3x)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(height)
            }
            errorLabel.snp.remakeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(addressField.snp.bottom).offset(CGFloat.margin1x)
                maker.height.equalTo(errorFieldHeight(text: error.localizedDescription))
                maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
            }
        } else {
            errorLabel.isHidden = true
            errorLabel.snp.removeConstraints()
            addressField.snp.remakeConstraints { maker in
                maker.leading.trailing.centerY.equalToSuperview()
                maker.height.equalTo(height)
            }
        }
    }

    private func errorFieldHeight(text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: addressWrapperView.bounds.width, font: errorFont)
        return textHeight
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
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
