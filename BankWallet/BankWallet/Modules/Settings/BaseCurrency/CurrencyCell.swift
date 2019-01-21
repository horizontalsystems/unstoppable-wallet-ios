import UIKit
import GrouviExtensions
import SnapKit

class CurrencyCell: UITableViewCell {
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    var checkmarkImageView = TintImageView(image: UIImage(named: "Transaction Success Icon"), tintColor: SettingsTheme.checkmarkTintColor, selectedTintColor: SettingsTheme.checkmarkTintColor)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SettingsTheme.cellBackground
        contentView.backgroundColor = .clear
//        separatorInset.left = self.layoutMargins.left * 2
        selectionStyle = .none

        titleLabel.font = SettingsTheme.titleFont
        titleLabel.textColor = SettingsTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalToSuperview().offset(SettingsTheme.cellMiddleMargin)
        }
        subtitleLabel.font = SettingsTheme.subtitleFont
        subtitleLabel.textColor = SettingsTheme.subtitleColor
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

    func bind(title: String, subtitle: String, selected: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        checkmarkImageView.isHidden = !selected
    }
}
