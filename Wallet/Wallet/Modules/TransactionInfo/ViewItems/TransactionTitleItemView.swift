import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionTitleItemView: BaseActionItemView {

    var titleLabel = UILabel()
    var amountLabel = UILabel()
    var dateLabel = UILabel()

    override var item: TransactionTitleItem? { return _item as? TransactionTitleItem }

    override func initView() {
        super.initView()
        backgroundColor = TransactionInfoTheme.titleBackground

        titleLabel.font = TransactionInfoTheme.titleFont
        titleLabel.textColor = TransactionInfoTheme.titleColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        amountLabel.font = TransactionInfoTheme.amountFont
        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(TransactionInfoTheme.smallMargin)
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
        titleLabel.text = item?.title

        amountLabel.text = item?.amount
        amountLabel.textColor = item?.amountColor

        dateLabel.text = item?.date
    }

}
