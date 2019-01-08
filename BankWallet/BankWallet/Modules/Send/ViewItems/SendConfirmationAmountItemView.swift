import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendConfirmationAmountItemView: BaseActionItemView {

    var currencyAmountLabel = UILabel()
    var amountLabel = UILabel()

    override var item: SendConfirmationAmounItem? { return _item as? SendConfirmationAmounItem }

    override func initView() {
        super.initView()

        backgroundColor = SendTheme.itemBackground

        currencyAmountLabel.font = SendTheme.confirmationCurrencyAmountFont
        currencyAmountLabel.textColor = SendTheme.confirmationCurrencyAmountColor
        addSubview(currencyAmountLabel)
        currencyAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(SendTheme.confirmationCurrencyAmountTopMargin)
        }

        amountLabel.font = SendTheme.confirmationAmountFont
        amountLabel.textColor = SendTheme.confirmationAmountColor
        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.currencyAmountLabel.snp.bottom).offset(SendTheme.confirmationAmountTopMargin)
        }
    }

    override func updateView() {
        super.updateView()

        currencyAmountLabel.text = item?.fiatAmount
        amountLabel.text = item?.amount
    }

}
