import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionAmountItemView: BaseActionItemView {

    var dateLabel = UILabel()
    var amountLabel = UILabel()
    var fiatAmountLabel = UILabel()

    override var item: TransactionAmountItem? { return _item as? TransactionAmountItem }

    override func initView() {
        super.initView()
        dateLabel.font = TransactionInfoTheme.dateFont
        dateLabel.textColor = TransactionInfoTheme.dateColor
        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        amountLabel.font = TransactionInfoTheme.amountFont
        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.dateLabel.snp.bottom).offset(TransactionInfoTheme.smallMargin)
        }

        fiatAmountLabel.font = TransactionInfoTheme.fiatAmountFont
        fiatAmountLabel.textColor = TransactionInfoTheme.fiatAmountColor
        addSubview(fiatAmountLabel)
        fiatAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.amountLabel.snp.bottom).offset(TransactionInfoTheme.smallMargin)
        }
    }

    override func updateView() {
        super.updateView()
        dateLabel.text = item?.date

        amountLabel.text = item?.amount
        amountLabel.textColor = item?.amountColor

        fiatAmountLabel.text = item?.fiatAmount
    }

}
