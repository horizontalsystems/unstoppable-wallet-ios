import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class ActionTitleItemView: BaseActionItemView {
    private let iconImageView = CoinIconImageView()
    private let titleLabel = UILabel()

    override var item: ActionTitleItem? { return _item as? ActionTitleItem }

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
            maker.trailing.equalToSuperview().offset(-SendTheme.mediumMargin)
            maker.centerY.equalTo(self.iconImageView.snp.centerY)
        }

        item?.bindTitle = { [weak self] title, coin in
            self?.iconImageView.bind(coin: coin)
            self?.titleLabel.text = title
        }
    }

}
