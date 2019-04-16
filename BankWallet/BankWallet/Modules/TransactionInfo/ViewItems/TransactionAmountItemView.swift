import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionAmountItemView: BaseActionItemView {

    var currencyAmountLabel = UILabel()
    var amountLabel = UILabel()
    var coinNameLabel = UILabel()

    override var item: TransactionAmountItem? { return _item as? TransactionAmountItem }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        currencyAmountLabel.font = TransactionInfoTheme.currencyAmountFont
        addSubview(currencyAmountLabel)
        currencyAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(TransactionInfoTheme.currencyAmountTopMargin)
        }

        amountLabel.font = TransactionInfoTheme.amountFont
        amountLabel.textColor = TransactionInfoTheme.amountColor
        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.currencyAmountLabel.snp.bottom).offset(TransactionInfoTheme.amountTopMargin)
        }

        addSubview(coinNameLabel)
        coinNameLabel.font = TransactionInfoTheme.coinNameFont
        coinNameLabel.textColor = TransactionInfoTheme.coinNameColor
        coinNameLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.amountLabel.snp.bottom).offset(TransactionInfoTheme.coinNameTopMargin)
        }
    }

    override func updateView() {
        super.updateView()

        currencyAmountLabel.text = item?.currencyAmount
        currencyAmountLabel.textColor = item?.currencyAmountColor

        amountLabel.text = item?.amount

        coinNameLabel.text = item?.coinName
    }

}
