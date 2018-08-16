import UIKit
import SnapKit

class SettingsCell: UITableViewCell {
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var disclosureImageView = UIImageView(image: UIImage(named: "Disclosure Indicator"))

    var selectWrapperView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = SettingsTheme.cellBackground
        separatorInset.left = 0

        selectWrapperView.backgroundColor = SettingsTheme.cellBackground
        contentView.addSubview(selectWrapperView)
        selectWrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        selectWrapperView.alpha = 0

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
            maker.size.equalTo(SettingsTheme.cellIconSize)
            maker.centerY.equalToSuperview()
        }
        titleLabel.textColor = SettingsTheme.textColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(SettingsTheme.cellBigMargin)
            maker.centerY.equalToSuperview()
        }

        contentView.addSubview(disclosureImageView)
        disclosureImageView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-self.layoutMargins.right * 2)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(SettingsTheme.disclosureSize)
        }

        let separator = UIView()
        separator.backgroundColor = SettingsTheme.cellBackground
        contentView.addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SettingsTheme.separatorInset + self.layoutMargins.left * 2)
            maker.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(titleIcon: UIImage?, title: String, showDisclosure: Bool = false) {
        iconImageView.image = titleIcon
        titleLabel.text = title
        disclosureImageView.isHidden = !showDisclosure
        disclosureImageView.snp.updateConstraints { maker in
            maker.width.equalTo(showDisclosure ? SettingsTheme.disclosureSize.width : 0)
            maker.trailing.equalToSuperview().offset(showDisclosure ? -self.layoutMargins.right : 0)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.selectWrapperView.alpha = highlighted ? 1 : 0
            }
        } else {
            selectWrapperView.alpha = highlighted ? 1 : 0
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.selectWrapperView.alpha = selected ? 1 : 0
            }
        } else {
            selectWrapperView.alpha = selected ? 1 : 0
        }
    }

}
