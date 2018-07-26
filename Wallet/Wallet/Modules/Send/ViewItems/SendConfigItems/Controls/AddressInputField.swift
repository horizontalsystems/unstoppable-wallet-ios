import UIKit

class AddressInputField: UIView {

    var addressInputField = UITextField()
    var pasteButton = RespondButton()

    public init() {
        super.init(frame: .zero)
        borderWidth = SendTheme.inputBorderWidth
        borderColor = SendTheme.inputBorderColor
        cornerRadius = SendTheme.inputCornerRadius

        addSubview(addressInputField)
        addressInputField.tintColor = SendTheme.inputTintColor
        addressInputField.textColor = SendTheme.inputTextColor
        addressInputField.font = SendTheme.inputFont
        addressInputField.placeholder = "send.address_placeholder".localized

        addSubview(pasteButton)
        pasteButton.borderWidth = 1 / UIScreen.main.scale
        pasteButton.borderColor = SendTheme.buttonBorderColor
        pasteButton.cornerRadius = SendTheme.buttonCornerRadius
        pasteButton.backgrounds = ButtonTheme.grayBackgroundDictionary
        pasteButton.textColors = SendTheme.buttonTextDictionary
        pasteButton.titleLabel.text = "paste".localized
        pasteButton.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addressInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalTo(pasteButton.snp.leading).offset(-SendTheme.smallMargin)
        }
        pasteButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SendTheme.buttonSideMargin)
            maker.trailing.bottom.equalToSuperview().offset(-SendTheme.buttonSideMargin)
        }
        pasteButton.titleLabel.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.buttonTitleMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.buttonTitleMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
