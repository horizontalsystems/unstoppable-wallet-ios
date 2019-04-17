import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendConfirmationAmountItemView: BaseActionItemView {

    var primaryAmountLabel = UILabel()
    var secondaryAmountLabel = UILabel()

    override var item: SendConfirmationAmounItem? { return _item as? SendConfirmationAmounItem }

    override func initView() {
        super.initView()

        backgroundColor = SendTheme.itemBackground

        primaryAmountLabel.font = SendTheme.confirmationCurrencyAmountFont
        primaryAmountLabel.textColor = SendTheme.confirmationCurrencyAmountColor
        addSubview(primaryAmountLabel)
        primaryAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(SendTheme.margin)
        }

        secondaryAmountLabel.font = SendTheme.confirmationAmountFont
        secondaryAmountLabel.textColor = SendTheme.confirmationAmountColor
        addSubview(secondaryAmountLabel)
        secondaryAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.primaryAmountLabel.snp.bottom).offset(SendTheme.confirmationAmountTopMargin)
        }
    }

    override func updateView() {
        super.updateView()

        primaryAmountLabel.text = item?.primaryAmount
        secondaryAmountLabel.text = item?.secondaryAmount
    }

}
