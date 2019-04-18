import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionTitleItemView: BaseActionItemView {

    let iconImageView = CoinIconImageView()
    let titleLabel = UILabel()
    let hashView = HashView()

    override var item: TransactionTitleItem? { return _item as? TransactionTitleItem }

    override func initView() {
        super.initView()

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.coinIconLeftMargin)
        }

        addSubview(titleLabel)
        titleLabel.text = "tx_info.title".localized
        titleLabel.font = TransactionInfoTheme.titleFont
        titleLabel.textColor = TransactionInfoTheme.titleColor
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(TransactionInfoTheme.higherMiddleMargin)
            maker.centerY.equalToSuperview()
        }

        addSubview(hashView)
        hashView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.higherMiddleMargin)
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.hashViewMargin)
            maker.centerY.equalToSuperview()
        }
    }

    override func updateView() {
        super.updateView()

        if let item = item {
            iconImageView.bind(coin: item.coin)
        }
        hashView.bind(value: item?.transactionHash, showExtra: .hash, onTap: { [weak self] in
            self?.item?.onIdTap?()
        })
    }

}
