import UIKit
import GrouviExtensions
import SnapKit

class LanguageCell: UITableViewCell {
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    var checkmarkImageView = TintImageView(image: UIImage(named: "Transaction Success Icon"), tintColor: SettingsTheme.languageCheckmarkTintColor, selectedTintColor: SettingsTheme.languageCheckmarkTintColor)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SettingsTheme.languageCellBackground
        contentView.backgroundColor = .clear
        separatorInset.left = self.layoutMargins.left * 2
        selectionStyle = .none

        titleLabel.font = SettingsTheme.languageTitleFont
        titleLabel.textColor = SettingsTheme.languageTitleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
            maker.top.equalToSuperview().offset(SettingsTheme.cellMiddleMargin)
        }
        subtitleLabel.font = SettingsTheme.languageSubtitleFont
        subtitleLabel.textColor = SettingsTheme.languageSubtitleColor
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(SettingsTheme.languageSubtitleTopMargin)
        }

        contentView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-self.layoutMargins.left * 2)
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
