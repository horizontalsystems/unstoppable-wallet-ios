import UIKit
import ActionSheet
import SnapKit

class AlertTitleItemView: BaseActionItemView {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()

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
            maker.centerY.equalTo(self.iconImageView.snp.centerY)
        }

        addSubview(closeButton)
        closeButton.setImage(UIImage(named: "Close Icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = AppTheme.closeButtonColor
        closeButton.addTarget(self, action: #selector(onTapClose), for: .touchUpInside)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(AppTheme.alertMediumMargin)
            maker.trailing.equalToSuperview().offset(-AppTheme.alertMediumMargin)
            maker.centerY.equalToSuperview()
        }

        iconImageView.image = item?.icon
        titleLabel.text = item?.title

        if let color = item?.iconTintColor {
            iconImageView.tintColor = color
        }
    }

    @objc func onTapClose() {
        item?.onClose()
    }

}
