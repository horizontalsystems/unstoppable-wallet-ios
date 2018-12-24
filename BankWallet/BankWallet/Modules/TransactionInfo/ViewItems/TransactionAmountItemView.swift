import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionAmountItemView: BaseActionItemView {

    var currencyAmountLabel = UILabel()
    var amountLabel = UILabel()

    override var item: TransactionAmountItem? { return _item as? TransactionAmountItem }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        currencyAmountLabel.font = TransactionInfoTheme.amountFont
        addSubview(currencyAmountLabel)
        currencyAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        amountLabel.font = TransactionInfoTheme.fiatAmountFont
        amountLabel.textColor = TransactionInfoTheme.fiatAmountColor
        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
        }
    }

    override func updateView() {
        super.updateView()

        currencyAmountLabel.text = item?.currencyAmount
        currencyAmountLabel.textColor = item?.currencyAmountColor

        amountLabel.text = item?.amount
    }

}
