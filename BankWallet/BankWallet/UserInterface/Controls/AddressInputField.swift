import UIKit
import SnapKit

class AddressInputField: UIView {
    private let addressWrapperView = UIView()
    private let addressLabel = UILabel()
    private let errorLabel = UILabel()
    private let scanButton = RespondButton()
    private let scanButtonIcon = UIImageView()
    private let deleteButton = RespondButton()
    private let deleteButtonIcon = UIImageView()
    private let pasteButton = RespondButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(addressWrapperView)
        addressWrapperView.addSubview(addressLabel)
        addressWrapperView.addSubview(errorLabel)
        addSubview(scanButton)
        scanButton.addSubview(scanButtonIcon)
        addSubview(deleteButton)
        deleteButton.addSubview(deleteButtonIcon)
        addSubview(pasteButton)

        layer.cornerRadius = SendTheme.holderCornerRadius
        layer.borderWidth = SendTheme.holderBorderWidth
        layer.borderColor = SendTheme.holderBorderColor.cgColor
        backgroundColor = SendTheme.holderBackground

        addressLabel.font = SendTheme.addressFont
        addressLabel.lineBreakMode = .byTruncatingMiddle

        errorLabel.font = SendTheme.errorFont
        errorLabel.textColor = SendTheme.errorColor

        pasteButton.borderWidth = 1 / UIScreen.main.scale
        pasteButton.borderColor = SendTheme.buttonBorderColor
        pasteButton.cornerRadius = SendTheme.buttonCornerRadius
        pasteButton.backgrounds = SendTheme.buttonBackground
        pasteButton.textColors = [.active: SendTheme.buttonIconColor, .selected: SendTheme.buttonIconColor]
        pasteButton.titleLabel.text = "button.paste".localized
        pasteButton.titleLabel.font = SendTheme.buttonFont
        pasteButton.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        pasteButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.switchRightMargin)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(SendTheme.buttonSize)
        }
        pasteButton.titleLabel.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.smallMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.smallMargin)
        }

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

    func bind(address: String?, error: String?) {
        if let address = address {
            addressLabel.text = address
            addressLabel.textColor = SendTheme.addressColor
            pasteButton.isHidden = true
            scanButton.isHidden = true
            deleteButton.isHidden = false

            addressWrapperView.snp.remakeConstraints { maker in
                maker.leading.equalToSuperview().offset(SendTheme.mediumMargin)
                maker.centerY.equalTo(deleteButton.snp.centerY)

                maker.trailing.equalTo(deleteButton.snp.leading).offset(-SendTheme.mediumMargin)
            }
        } else {
            addressLabel.text = "send.address_placeholder".localized
            addressLabel.textColor = SendTheme.addressHintColor
            pasteButton.isHidden = false
            scanButton.isHidden = false
            deleteButton.isHidden = true

            addressWrapperView.snp.remakeConstraints { maker in
                maker.leading.equalToSuperview().offset(SendTheme.mediumMargin)
                maker.centerY.equalTo(pasteButton.snp.centerY)

                maker.trailing.equalTo(pasteButton.snp.leading).offset(-SendTheme.mediumMargin)
            }
        }

        if let error = error {
            errorLabel.isHidden = false
            errorLabel.text = error

            addressLabel.snp.remakeConstraints { maker in
                maker.leading.top.trailing.equalToSuperview()
            }
            errorLabel.snp.remakeConstraints { maker in
                maker.leading.bottom.trailing.equalToSuperview()
                maker.top.equalTo(addressLabel.snp.bottom).offset(SendTheme.addressErrorTopMargin)
            }
        } else {
            errorLabel.isHidden = true
            addressLabel.snp.remakeConstraints { maker in
                maker.leading.top.bottom.trailing.equalToSuperview()
            }
        }

    }

}
