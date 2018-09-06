import UIKit
import GrouviExtensions
import SnapKit

class SecurityCell: UITableViewCell {
    var titleLabel = UILabel()
    var checkmarkImageView = TintImageView(image: UIImage(named: "Transaction Success Icon"), tintColor: SettingsTheme.languageCheckmarkTintColor, selectedTintColor: SettingsTheme.languageCheckmarkTintColor)

    var selectView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SettingsTheme.languageCellBackground
        contentView.backgroundColor = .clear
        separatorInset.left = self.layoutMargins.left * 2

        selectView.backgroundColor = SettingsTheme.cellSelectBackground
        contentView.addSubview(selectView)
        selectView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        selectView.alpha = 0

        titleLabel.font = SettingsTheme.languageTitleFont
        titleLabel.textColor = SettingsTheme.languageTitleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
            maker.centerY.equalToSuperview()
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

    func bind(title: String, checked: Bool) {
        titleLabel.text = title

        checkmarkImageView.isHidden = !checked
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
