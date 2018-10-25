import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendAmountItemView: BaseActionItemView {

    var addressInputField = AddressInputField()
    var amountInputField = AmountInputField()
//    var moreButton = RespondButton()
    var errorLabel = UILabel()

    override var item: SendAmountItem? { return _item as? SendAmountItem }

    override func initView() {
        super.initView()

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SendTheme.sideMargin)
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
            maker.height.equalTo(SendTheme.addressHeight)
        }
        addSubview(amountInputField)
        amountInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.equalTo(self.addressInputField.snp.bottom).offset(SendTheme.inputFieldsGap)
            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
            maker.height.equalTo(SendTheme.amountHeight)
        }

//        moreButton.textColors = [RespondButton.State.active: SendTheme.moreButtonTextColor, RespondButton.State.selected: SendTheme.moreButtonTextSelectedColor]
//        moreButton.titleLabel.text = "moreg".localized
//        moreButton.titleLabel.snp.remakeConstraints { maker in
//            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
//            maker.top.equalToSuperview().offset(SendTheme.backButtonTopMargin)
//        }
//        addSubview(moreButton)
//        moreButton.snp.makeConstraints { maker in
//            maker.leading.trailing.bottom.equalToSuperview()
//            maker.top.equalTo(amountInputField.snp.bottom)
//        }

        errorLabel.textColor = SendTheme.errorColor
        errorLabel.font = SendTheme.errorFont
        addSubview(errorLabel)
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.equalTo(amountInputField.snp.bottom).offset(SendTheme.smallestMargin)
        }

        item?.reload = { [weak self] in
            self?.bind()
        }
        bind()
    }

    override func updateView() {
        super.updateView()
        bind()
    }

    func bind() {
        item?.showKeyboardOnLoad = { [weak self] in
            DispatchQueue.main.async {
                self?.addressInputField.addressInputField.becomeFirstResponder()
            }
        }

//        moreButton.onTap = item?.onMore

        addressInputField.pasteButton.onTap = item?.onPaste
        addressInputField.onAddressChange = { [weak self] in
            self?.item?.address = $0
            self?.item?.onAddressEntered?($0)
        }
        addressInputField.addressInputField.text = item?.address
        addressInputField.borderColor = (item?.addressValid ?? true) ? SendTheme.inputBorderColor : SendTheme.errorColor

        amountInputField.currencyButton.onTap = item?.onCurrencyChange
        amountInputField.currencyButton.titleLabel.text = item?.currencyCode
        amountInputField.onAmountChange = { [weak self] in
            self?.item?.amount = $0
            self?.item?.onAmountEntered?($0)
        }
        amountInputField.exchangeValueLabel.textColor = item?.hintColor
        amountInputField.exchangeValueLabel.text = item?.hint

        errorLabel.text = item?.error?.localizedDescription ?? nil
        amountInputField.borderColor = item?.error == nil ? SendTheme.inputBorderColor : SendTheme.errorColor
    }

}
