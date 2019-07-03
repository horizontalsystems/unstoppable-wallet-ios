import UIKit
import SnapKit

class ManageAccountCell: UITableViewCell {
    private let roundedBackground = UIView()
    private let clippingView = UIView()

    private let backedUpIcon = UIImageView()
    private let nameLabel = UILabel()
    private let coinsLabel = UILabel()

    private let unlinkButton = RespondButton()
    private let backupButton = RespondButton()

    private var onUnlink: (() -> ())?
    private var onBackup: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(roundedBackground)
        roundedBackground.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leadingMargin.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.bottom.equalToSuperview().offset(-ManageAccountsTheme.cellBottomMargin)
        }
        roundedBackground.backgroundColor = ManageAccountsTheme.roundedBackgroundColor
        roundedBackground.layer.shadowOpacity = ManageAccountsTheme.roundedBackgroundShadowOpacity
        roundedBackground.layer.cornerRadius = ManageAccountsTheme.roundedBackgroundCornerRadius
        roundedBackground.layer.shadowColor = ManageAccountsTheme.roundedBackgroundShadowColor.cgColor
        roundedBackground.layer.shadowRadius = 4
        roundedBackground.layer.shadowOffset = CGSize(width: 0, height: 4)

        roundedBackground.addSubview(clippingView)
        clippingView.backgroundColor = .clear
        clippingView.clipsToBounds = true
        clippingView.layer.cornerRadius = ManageAccountsTheme.roundedBackgroundCornerRadius
        clippingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        clippingView.addSubview(backedUpIcon)
        backedUpIcon.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellBigPadding)
            maker.top.equalToSuperview().offset(ManageAccountsTheme.cellBigPadding)
        }
        backedUpIcon.image = UIImage(named: "Attention Icon")

        clippingView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ManageAccountsTheme.cellBigPadding)
            maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellBigPadding)
            maker.top.equalToSuperview().offset(ManageAccountsTheme.cellBigPadding)
        }
        nameLabel.textAlignment = .center
        nameLabel.font = ManageAccountsTheme.cellTitleFont
        nameLabel.textColor = ManageAccountsTheme.cellTitleColor
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clippingView.addSubview(coinsLabel)
        coinsLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ManageAccountsTheme.cellBigPadding)
            maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellBigPadding)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(ManageAccountsTheme.cellSmallPadding)
        }
        coinsLabel.textAlignment = .center
        coinsLabel.font = ManageAccountsTheme.coinsFont
        coinsLabel.textColor = ManageAccountsTheme.coinsColor
        coinsLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        coinsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clippingView.addSubview(unlinkButton)
        unlinkButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ManageAccountsTheme.cellSmallPadding)
            maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
            maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
        }
        unlinkButton.onTap = { [weak self] in self?.onUnlink?() }
        unlinkButton.backgrounds = ButtonTheme.redBackgroundOnWhiteBackgroundDictionary
        unlinkButton.cornerRadius = ManageAccountsTheme.buttonCornerRadius
        unlinkButton.titleLabel.text = "settings_manage_accounts.unlink".localized

        clippingView.addSubview(backupButton)
        backupButton.snp.makeConstraints { maker in
            maker.leading.equalTo(unlinkButton.snp.trailing).offset(ManageAccountsTheme.cellSmallPadding)
            maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
            maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellSmallPadding)
            maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
            maker.width.equalTo(unlinkButton)
        }
        backupButton.onTap = { [weak self] in self?.onBackup?() }
        backupButton.backgrounds = ButtonTheme.yellowBackgroundOnDarkBackgroundDictionary
        backupButton.cornerRadius = ManageAccountsTheme.buttonCornerRadius
        backupButton.titleLabel.text = "settings_manage_accounts.backup".localized
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(account: Account, onUnlink: @escaping () -> (), onBackup: @escaping () -> ()) {
        backedUpIcon.isHidden = account.backedUp

        let predefinedAccountType = account.type.predefinedAccountType

        nameLabel.text = predefinedAccountType?.title.localized
        coinsLabel.text = predefinedAccountType?.coinCodes

        self.onUnlink = onUnlink
        self.onBackup = onBackup
    }

}
