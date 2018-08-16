import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionAmountItemView: BaseActionItemView {

    var amountLabel = UILabel()
    var dateLabel = UILabel()

    override var item: TransactionAmountItem? { return _item as? TransactionAmountItem }

    override func initView() {
        super.initView()
        amountLabel.font = TransactionInfoTheme.amountFont
        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(TransactionInfoTheme.middleMargin)
        }

        dateLabel.font = TransactionInfoTheme.dateFont
        dateLabel.textColor = TransactionInfoTheme.dateColor
        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.amountLabel.snp.bottom).offset(TransactionInfoTheme.smallMargin)
        }

    }

    override func updateView() {
        super.updateView()
        amountLabel.text = item?.amount
        amountLabel.textColor = item?.amountColor

        dateLabel.text = item?.date
    }

}
