import UIKit
import ActionSheet
import SnapKit

class TransactionTitleItemView: BaseActionItemView {
    private let iconImageView = CoinIconImageView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()

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

        closeButton.setImage(UIImage(named: "Close Icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = AppTheme.closeButtonColor
        closeButton.addTarget(self, action: #selector(onTapClose), for: .touchUpInside)

        addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.higherMiddleMargin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.higherMiddleMargin)
            maker.centerY.equalToSuperview()
        }
    }

    override func updateView() {
        super.updateView()

        if let item = item {
            iconImageView.bind(coin: item.coin)
        }
    }

    @objc func onTapClose() {
        item?.onClose?()
    }

}
