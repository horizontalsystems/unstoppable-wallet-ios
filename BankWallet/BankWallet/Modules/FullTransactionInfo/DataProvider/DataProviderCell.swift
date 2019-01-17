import UIKit
import GrouviExtensions
import SnapKit

class DataProviderCell: UITableViewCell {
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    var checkmarkImageView = TintImageView(image: UIImage(named: "Transaction Success Icon"), tintColor: SettingsTheme.checkmarkTintColor, selectedTintColor: SettingsTheme.checkmarkTintColor)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SettingsTheme.cellBackground
        contentView.backgroundColor = .clear
        selectionStyle = .none

        titleLabel.font = SettingsTheme.titleFont
        titleLabel.textColor = SettingsTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalToSuperview().offset(SettingsTheme.cellMiddleMargin)
        }
        subtitleLabel.font = SettingsTheme.subtitleFont
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(SettingsTheme.subtitleTopMargin)
        }

        contentView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func bind(title: String, online: Bool, selected: Bool) {
        titleLabel.text = title
        if online {
            subtitleLabel.text = "settings_provider.online".localized
            subtitleLabel.textColor = SettingsTheme.onlineSubtitleColor
        } else {
            subtitleLabel.text = "settings_provider.offline".localized
            subtitleLabel.textColor = SettingsTheme.offlineSubtitleColor
        }

        checkmarkImageView.isHidden = !selected
    }
}
