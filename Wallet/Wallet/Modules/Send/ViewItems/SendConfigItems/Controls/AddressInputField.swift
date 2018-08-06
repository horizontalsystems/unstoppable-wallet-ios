import UIKit
import RxSwift
import RxCocoa

class AddressInputField: UIView {

    var addressInputField = UITextField()
    var pasteButton = RespondButton()
    var onAddressChange: ((String?) -> ())?

    let disposeBag = DisposeBag()

    public init() {
        super.init(frame: .zero)
        backgroundColor = AppTheme.inputBackgroundColor
        borderWidth = SendTheme.inputBorderWidth
        borderColor = SendTheme.inputBorderColor
        cornerRadius = SendTheme.inputCornerRadius

        addSubview(addressInputField)
        addressInputField.autocorrectionType = .no
        addressInputField.tintColor = SendTheme.inputTintColor
        addressInputField.textColor = SendTheme.inputTextColor
        addressInputField.font = SendTheme.inputFont
        addressInputField.placeholder = "send.address_placeholder".localized
        addressInputField.rx.controlEvent(.editingChanged).subscribe(onNext: { [weak self] _ in
            self?.onAddressChange?(self?.addressInputField.text)
        }).disposed(by: disposeBag)

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
