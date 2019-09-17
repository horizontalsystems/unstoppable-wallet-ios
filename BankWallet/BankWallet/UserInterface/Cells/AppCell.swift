import UIKit
import UIExtensions
import SnapKit

class AppCell: UITableViewCell {
    private let selectView = UIView()

    private let topSeparatorView = UIView()
    private let bottomSeparatorView = UIView()

    let disclosureImageView = UIImageView(image: UIImage(named: "Disclosure Indicator"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .appLawrence
        contentView.backgroundColor = .clear
        separatorInset.left = 0

        topSeparatorView.backgroundColor = AppTheme.separatorColor
        contentView.addSubview(topSeparatorView)
        topSeparatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }

        bottomSeparatorView.backgroundColor = AppTheme.darkSeparatorColor
        contentView.addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(0)
        }

        selectView.backgroundColor = .cryptoSteel20
        contentView.addSubview(selectView)
        selectView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(self.topSeparatorView.snp.bottom)
            maker.bottom.equalTo(self.bottomSeparatorView.snp.top)
        }
        selectView.alpha = 0

        contentView.addSubview(disclosureImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(showDisclosure: Bool = false, last: Bool = false) {
        disclosureImageView.isHidden = !showDisclosure
        disclosureImageView.snp.remakeConstraints { maker in
            maker.trailing.equalTo(contentView.snp.trailingMargin)
            maker.size.equalTo(showDisclosure ? SettingsTheme.disclosureSize : 0)
            maker.centerY.equalToSuperview()
        }

        bottomSeparatorView.snp.updateConstraints { maker in
            maker.height.equalTo(last ? 1 / UIScreen.main.scale : 0)
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
