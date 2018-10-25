import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionAmountItemView: BaseActionItemView {

    var amountLabel = UILabel()
    var fiatAmountLabel = UILabel()

    override var item: TransactionAmountItem? { return _item as? TransactionAmountItem }

    override func initView() {
        super.initView()
        backgroundColor = TransactionInfoTheme.titleBackground

        amountLabel.font = TransactionInfoTheme.amountFont
        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(TransactionInfoTheme.amountTopMargin)
        }

        fiatAmountLabel.font = TransactionInfoTheme.fiatAmountFont
        fiatAmountLabel.textColor = TransactionInfoTheme.fiatAmountColor
        addSubview(fiatAmountLabel)
        fiatAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.amountLabel.snp.bottom).offset(TransactionInfoTheme.middleMargin)
        }
    }

    override func updateView() {
        super.updateView()
        amountLabel.text = item?.amount
        amountLabel.textColor = item?.amountColor

        fiatAmountLabel.text = item?.fiatAmount
    }

}
