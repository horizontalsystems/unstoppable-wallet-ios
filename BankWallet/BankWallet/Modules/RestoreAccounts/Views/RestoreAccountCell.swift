import UIKit
import SnapKit

class RestoreAccountCell: UITableViewCell {
    private let roundedBackground = UIView()
    private let clippingView = UIView()

    private let nameLabel = UILabel()
    private let coinsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .default

        contentView.addSubview(roundedBackground)
        roundedBackground.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leadingMargin.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.bottom.equalToSuperview().offset(-RestoreAccountsTheme.cellBottomMargin)
        }
        roundedBackground.backgroundColor = RestoreAccountsTheme.roundedBackgroundColor
        roundedBackground.layer.shadowOpacity = RestoreAccountsTheme.roundedBackgroundShadowOpacity
        roundedBackground.layer.cornerRadius = RestoreAccountsTheme.roundedBackgroundCornerRadius
        roundedBackground.layer.shadowColor = RestoreAccountsTheme.roundedBackgroundShadowColor.cgColor
        roundedBackground.layer.shadowRadius = 4
        roundedBackground.layer.shadowOffset = CGSize(width: 0, height: 4)

        roundedBackground.addSubview(clippingView)
        clippingView.backgroundColor = .clear
        clippingView.clipsToBounds = true
        clippingView.layer.cornerRadius = RestoreAccountsTheme.roundedBackgroundCornerRadius
        clippingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        clippingView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(RestoreAccountsTheme.cellBigPadding)
            maker.trailing.equalToSuperview().offset(-RestoreAccountsTheme.cellBigPadding)
            maker.top.equalToSuperview().offset(RestoreAccountsTheme.cellBigPadding)
        }
        nameLabel.textAlignment = .center
        nameLabel.font = RestoreAccountsTheme.cellTitleFont
        nameLabel.textColor = RestoreAccountsTheme.cellTitleColor
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clippingView.addSubview(coinsLabel)
        coinsLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(RestoreAccountsTheme.cellBigPadding)
            maker.trailing.equalToSuperview().offset(-RestoreAccountsTheme.cellBigPadding)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(RestoreAccountsTheme.cellSmallPadding)
        }
        coinsLabel.textAlignment = .center
        coinsLabel.font = RestoreAccountsTheme.coinsFont
        coinsLabel.textColor = RestoreAccountsTheme.coinsColor
        coinsLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        coinsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String, coinCodes: String) {
        nameLabel.text = title.localized
        coinsLabel.text = coinCodes
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.roundedBackground.backgroundColor = highlighted ? RestoreAccountsTheme.roundedSelectedBackgroundColor : RestoreAccountsTheme.roundedBackgroundColor
            }
        } else {
            roundedBackground.backgroundColor = highlighted ? RestoreAccountsTheme.roundedSelectedBackgroundColor : RestoreAccountsTheme.roundedBackgroundColor
        }

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.roundedBackground.backgroundColor = selected ? RestoreAccountsTheme.roundedSelectedBackgroundColor : RestoreAccountsTheme.roundedBackgroundColor
            }
        } else {
            roundedBackground.backgroundColor = selected ? RestoreAccountsTheme.roundedSelectedBackgroundColor : RestoreAccountsTheme.roundedBackgroundColor
        }

    }

}
