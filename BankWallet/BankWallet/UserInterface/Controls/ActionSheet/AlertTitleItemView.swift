import UIKit
import ActionSheet
import SnapKit

class AlertTitleItemView: BaseActionItemView {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()

    override var item: AlertTitleItem? { return _item as? AlertTitleItem }

    override func initView() {
        super.initView()

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(AppTheme.alertMediumMargin)
            maker.size.equalTo(AppTheme.coinIconSize)
        }

        addSubview(titleLabel)
        titleLabel.font = AppTheme.alertTitleFont
        titleLabel.textColor = AppTheme.alertTitleColor
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(AppTheme.alertSmallMargin)
            maker.trailing.equalToSuperview().offset(-AppTheme.alertMediumMargin)
            maker.centerY.equalTo(self.iconImageView.snp.centerY)
        }

        iconImageView.image = item?.icon
        titleLabel.text = item?.title

        if let color = item?.iconTintColor {
            iconImageView.tintColor = color
        }
    }

}
