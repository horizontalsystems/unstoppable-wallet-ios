import UIKit
import UIExtensions
import SnapKit

class DoubleLineCell: UITableViewCell {
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    var iconImageView = TintImageView()
    var checkmarkImageView = TintImageView(image: UIImage(named: "Transaction Success Icon"), tintColor: SettingsTheme.checkmarkTintColor, selectedTintColor: SettingsTheme.checkmarkTintColor)
    let bottomSeparatorView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = SettingsTheme.cellBackground
        contentView.backgroundColor = .clear

        let backgroundView = UIView()
        backgroundView.backgroundColor = SettingsTheme.cellSelectBackground
        selectedBackgroundView = backgroundView

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(contentView.snp.leadingMargin)
        }
        titleLabel.font = SettingsTheme.titleFont
        titleLabel.textColor = SettingsTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(SettingsTheme.cellBigMargin)
            maker.top.equalToSuperview().offset(SettingsTheme.cellMiddleMargin)
        }
        subtitleLabel.font = SettingsTheme.subtitleFont
        subtitleLabel.textColor = SettingsTheme.subtitleColor
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(SettingsTheme.cellBigMargin)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(SettingsTheme.subtitleTopMargin)
        }

        contentView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }

        bottomSeparatorView.backgroundColor = AppTheme.separatorColor
        addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func bind(icon: UIImage?, tintIcon: Bool = false, title: String, subtitle: String, selected: Bool = false, last: Bool = false) {
        if tintIcon {
            iconImageView.tintColor = SettingsTheme.iconTintColor
        }

        iconImageView.image = icon
        titleLabel.text = title
        subtitleLabel.text = subtitle

        checkmarkImageView.isHidden = !selected

        bottomSeparatorView.isHidden = last

    }
}
