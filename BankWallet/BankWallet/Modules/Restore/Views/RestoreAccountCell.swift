import UIKit
import SnapKit

class RestoreAccountCell: UITableViewCell {
    private let roundedBackground = UIView()
    private let clippingView = UIView()

    private let keyIconImageView = UIImageView()
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
            maker.leading.trailing.equalToSuperview().inset(AppTheme.viewMargin)
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

        clippingView.addSubview(keyIconImageView)
        clippingView.addSubview(nameLabel)
        clippingView.addSubview(coinsLabel)

        keyIconImageView.image = UIImage(named: "Key Icon")?.withRenderingMode(.alwaysTemplate)
        keyIconImageView.tintColor = RestoreAccountsTheme.keyImageColor
        keyIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(RestoreAccountsTheme.cellBigPadding)
            maker.top.equalToSuperview().offset(RestoreAccountsTheme.cellSmallPadding)
            maker.size.equalTo(RestoreAccountsTheme.keyImageSize)
        }

        nameLabel.font = RestoreAccountsTheme.cellTitleFont
        nameLabel.textColor = RestoreAccountsTheme.cellTitleColor
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.keyIconImageView.snp.trailing).offset(RestoreAccountsTheme.cellSmallPadding)
            maker.trailing.equalToSuperview().offset(-RestoreAccountsTheme.cellBigPadding)
            maker.top.equalToSuperview().offset(RestoreAccountsTheme.cellSmallPadding)
        }

        coinsLabel.font = RestoreAccountsTheme.coinsFont
        coinsLabel.textColor = RestoreAccountsTheme.coinsColor
        coinsLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.nameLabel.snp.leading)
            maker.trailing.equalToSuperview().offset(-RestoreAccountsTheme.cellBigPadding)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(RestoreAccountsTheme.cellSmallPadding)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(predefinedAccountType: IPredefinedAccountType) {
        nameLabel.text = predefinedAccountType.title.localized
        coinsLabel.text = predefinedAccountType.coinCodes.localized
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
