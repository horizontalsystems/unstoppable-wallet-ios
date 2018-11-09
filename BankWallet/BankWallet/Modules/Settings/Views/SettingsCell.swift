import UIKit
import SnapKit

class SettingsCell: UITableViewCell {
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var disclosureImageView = UIImageView(image: UIImage(named: "Disclosure Indicator"))

    var selectView = UIView()
    let separator = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SettingsTheme.cellBackground
        contentView.backgroundColor = .clear
        separatorInset.left = 0

        selectView.backgroundColor = SettingsTheme.cellSelectBackground
        contentView.addSubview(selectView)
        selectView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        selectView.alpha = 0

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.size.equalTo(SettingsTheme.cellIconSize)
            maker.centerY.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(SettingsTheme.cellBigMargin)
            maker.centerY.equalToSuperview()
        }

        contentView.addSubview(disclosureImageView)
        disclosureImageView.snp.makeConstraints { maker in
            maker.trailing.equalTo(contentView.snp.trailingMargin)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(SettingsTheme.disclosureSize)
        }

        separator.backgroundColor = SettingsTheme.cellSelectBackground
        contentView.addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin).offset(SettingsTheme.separatorInset)
            maker.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(titleIcon: UIImage?, title: String, titleColor: UIColor = SettingsTheme.textColor, showDisclosure: Bool = false, last: Bool = false) {
        iconImageView.snp.updateConstraints { maker in
            let sideSize = titleIcon != nil ? SettingsTheme.cellIconSize : 0
            maker.size.equalTo(sideSize)
        }
        titleLabel.snp.updateConstraints { maker in
            let margin = titleIcon != nil ? SettingsTheme.cellBigMargin : 0
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(margin)
        }

        iconImageView.image = titleIcon

        titleLabel.text = title
        titleLabel.textColor = titleColor

        disclosureImageView.isHidden = !showDisclosure
        disclosureImageView.snp.remakeConstraints { maker in
            if showDisclosure {
                maker.trailing.equalTo(contentView.snp.trailingMargin)
            } else {
                maker.trailing.equalToSuperview()
            }
            maker.centerY.equalToSuperview()
            maker.size.equalTo(SettingsTheme.disclosureSize)
        }

        if last {
            separator.isHidden = true
        } else {
            separator.isHidden = false
            separator.snp.updateConstraints { maker in
                let float = (titleIcon != nil ? SettingsTheme.separatorInset : 0)
                maker.leading.equalTo(contentView.snp.leadingMargin).offset(float)
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.selectView.alpha = highlighted ? 1 : 0
            }
        } else {
            selectView.alpha = highlighted ? 1 : 0
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.selectView.alpha = selected ? 1 : 0
            }
        } else {
            selectView.alpha = selected ? 1 : 0
        }
    }

}
