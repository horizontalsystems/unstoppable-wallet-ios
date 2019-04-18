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

        let centerView = UIView()
        addSubview(centerView)
        centerView.backgroundColor = .clear
        centerView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        currencyAmountLabel.font = TransactionInfoTheme.currencyAmountFont
        centerView.addSubview(currencyAmountLabel)
        currencyAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview()
        }

        amountLabel.font = TransactionInfoTheme.amountFont
        amountLabel.textColor = TransactionInfoTheme.amountColor
        centerView.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.currencyAmountLabel.snp.bottom).offset(TransactionInfoTheme.amountTopMargin)
        }

        centerView.addSubview(coinNameLabel)
        coinNameLabel.font = TransactionInfoTheme.coinNameFont
        coinNameLabel.textColor = TransactionInfoTheme.coinNameColor
        coinNameLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.amountLabel.snp.bottom).offset(TransactionInfoTheme.coinNameTopMargin)
            maker.bottom.equalToSuperview()
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
