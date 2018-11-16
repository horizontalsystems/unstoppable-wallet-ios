import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendAddressItemView: BaseActionItemView {
    private let addressWrapperView = UIView()
    private let addressLabel = UILabel()
    private let errorLabel = UILabel()
    private let scanButton = RespondButton()
    private let scanButtonIcon = UIImageView()
    private let deleteButton = RespondButton()
    private let deleteButtonIcon = UIImageView()
    private let pasteButton = RespondButton()

    override var item: SendAddressItem? { return _item as? SendAddressItem }

    override func initView() {
        super.initView()

        addSubview(addressWrapperView)
        addressWrapperView.addSubview(addressLabel)
        addressWrapperView.addSubview(errorLabel)
        addSubview(scanButton)
        scanButton.addSubview(scanButtonIcon)
        addSubview(deleteButton)
        deleteButton.addSubview(deleteButtonIcon)
        addSubview(pasteButton)

        addressLabel.font = SendTheme.addressFont
        addressLabel.lineBreakMode = .byTruncatingMiddle

        errorLabel.font = SendTheme.errorFont
        errorLabel.textColor = SendTheme.errorColor

        pasteButton.borderWidth = 1 / UIScreen.main.scale
        pasteButton.borderColor = SendTheme.buttonBorderColor
        pasteButton.cornerRadius = SendTheme.buttonCornerRadius
        pasteButton.backgrounds = ButtonTheme.grayBackgroundDictionary
        pasteButton.titleLabel.text = "paste".localized
        pasteButton.titleLabel.font = SendTheme.buttonFont
        pasteButton.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        pasteButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.margin)
            maker.height.equalTo(SendTheme.buttonSize)
        }
        pasteButton.titleLabel.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.buttonTitleHorizontalMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.buttonTitleHorizontalMargin)
        }

        scanButton.borderWidth = 1 / UIScreen.main.scale
        scanButton.borderColor = SendTheme.buttonBorderColor
        scanButton.cornerRadius = SendTheme.buttonCornerRadius
        scanButton.backgrounds = ButtonTheme.grayBackgroundDictionary
        scanButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(pasteButton.snp.leading).offset(-SendTheme.smallMargin)
            maker.centerY.equalTo(pasteButton.snp.centerY)
            maker.size.equalTo(SendTheme.buttonSize)
        }

        scanButtonIcon.image = UIImage(named: "Send Scan Icon")
        scanButtonIcon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        deleteButton.borderWidth = 1 / UIScreen.main.scale
        deleteButton.borderColor = SendTheme.buttonBorderColor
        deleteButton.cornerRadius = SendTheme.buttonCornerRadius
        deleteButton.backgrounds = ButtonTheme.grayBackgroundDictionary
        deleteButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.margin)
            maker.centerY.equalTo(pasteButton.snp.centerY)
            maker.size.equalTo(SendTheme.buttonSize)
        }

        deleteButtonIcon.image = UIImage(named: "Send Delete Icon")
        deleteButtonIcon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        pasteButton.onTap = item?.onPasteClicked
        scanButton.onTap = item?.onScanClicked
        deleteButton.onTap = item?.onDeleteClicked

        item?.bindAddress = { [weak self] address, error in
            self?.bind(address: address, error: error)
        }

        bind(address: nil, error: nil)
    }

    private func bind(address: String?, error: String?) {
        if let address = address {
            addressLabel.text = address
            addressLabel.textColor = SendTheme.addressColor
            pasteButton.isHidden = true
            scanButton.isHidden = true
            deleteButton.isHidden = false

            addressWrapperView.snp.remakeConstraints { maker in
                maker.leading.equalToSuperview().offset(SendTheme.margin)
                maker.centerY.equalTo(deleteButton.snp.centerY)
                maker.trailing.equalTo(deleteButton.snp.leading).offset(-SendTheme.margin)
            }
        } else {
            addressLabel.text = "send.address_placeholder".localized
            addressLabel.textColor = SendTheme.addressHintColor
            pasteButton.isHidden = false
            scanButton.isHidden = false
            deleteButton.isHidden = true

            addressWrapperView.snp.remakeConstraints { maker in
                maker.leading.equalToSuperview().offset(SendTheme.margin)
                maker.centerY.equalTo(pasteButton.snp.centerY)
                maker.trailing.equalTo(pasteButton.snp.leading).offset(-SendTheme.margin)
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
                maker.edges.equalToSuperview()
            }
        }

    }

}
