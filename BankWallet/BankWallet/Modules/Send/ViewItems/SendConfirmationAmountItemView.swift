import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendConfirmationAmountItemView: BaseActionItemView {

    var amountLabel = UILabel()
    var fiatAmountLabel = UILabel()

    override var item: SendConfirmationAmounItem? { return _item as? SendConfirmationAmounItem }

    override func initView() {
        super.initView()

        backgroundColor = SendTheme.itemBackground

        amountLabel.font = SendTheme.confirmationAmountFont
        amountLabel.textColor = SendTheme.confirmationAmountColor
        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(SendTheme.confirmationAmountTopMargin)
        }

        fiatAmountLabel.font = SendTheme.confirmationFiatAmountFont
        fiatAmountLabel.textColor = SendTheme.confirmationFiatAmountColor
        addSubview(fiatAmountLabel)
        fiatAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.amountLabel.snp.bottom).offset(SendTheme.confirmationFiatAmountTopMargin)
        }
    }

    override func updateView() {
        super.updateView()

        amountLabel.text = item?.amount
        fiatAmountLabel.text = item?.fiatAmount
    }

}
