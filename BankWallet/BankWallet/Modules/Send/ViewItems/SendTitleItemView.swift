import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendTitleItemView: BaseActionItemView {
    private let iconImageView = CoinIconImageView()
    private let titleLabel = UILabel()

    override var item: SendTitleItem? { return _item as? SendTitleItem }

    override func initView() {
        super.initView()

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(SendTheme.mediumMargin)
        }

        titleLabel.font = SendTheme.titleFont
        titleLabel.textColor = SendTheme.titleColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(SendTheme.smallMargin)
            maker.centerY.equalTo(self.iconImageView.snp.centerY)
        }

        item?.bindCoin = { [weak self] coin in
            self?.iconImageView.bind(coin: coin)
            self?.titleLabel.text = "send.title".localized(coin.title)
        }
    }

}
