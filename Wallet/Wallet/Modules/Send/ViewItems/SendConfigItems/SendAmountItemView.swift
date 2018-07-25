import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendAmountItemView: BaseActionItemView {

    var addressInputField = AddressInputField()
    var amountInputField = AmountInputField()
    var moreButton = RespondButton()
    var errorLabel = UILabel()

    override var item: SendAmountItem? { return _item as? SendAmountItem }

    override func initView() {
        super.initView()

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(SendTheme.sideMargin)
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

        moreButton.textColors = [RespondButton.State.active: SendTheme.moreButtonTextColor, RespondButton.State.selected: SendTheme.moreButtonTextSelectedColor]
        moreButton.titleLabel.text = "more".localized
        moreButton.titleLabel.snp.remakeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
            maker.centerY.equalToSuperview()
        }
        addSubview(moreButton)
        moreButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(amountInputField.snp.bottom)
        }

        errorLabel.textColor = SendTheme.errorColor
        errorLabel.font = SendTheme.errorFont
        addSubview(errorLabel)
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.equalTo(amountInputField.snp.bottom).offset(SendTheme.smallestMargin)
        }
    }

    override func updateView() {
        super.updateView()
    }

}
