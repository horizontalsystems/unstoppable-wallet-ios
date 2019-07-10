import UIKit
import SnapKit

class ManageAccountCell: UITableViewCell {
    private let roundedBackground = UIView()
    private let clippingView = UIView()

    private let backedUpIcon = UIImageView()
    private let nameLabel = UILabel()
    private let coinsLabel = UILabel()

    private let leftButton = RespondButton()
    private let rightButton = RespondButton()

    private var onTapLeft: (() -> ())?
    private var onTapRight: (() -> ())?

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

        clippingView.addSubview(leftButton)
        leftButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ManageAccountsTheme.cellSmallPadding)
            maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
            maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
        }
        leftButton.onTap = { [weak self] in self?.onTapLeft?() }
        leftButton.backgrounds = ButtonTheme.redBackgroundDictionary
        leftButton.cornerRadius = ManageAccountsTheme.buttonCornerRadius

        clippingView.addSubview(rightButton)
        rightButton.snp.makeConstraints { maker in
            maker.leading.equalTo(leftButton.snp.trailing).offset(ManageAccountsTheme.cellSmallPadding)
            maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
            maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellSmallPadding)
            maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
            maker.width.equalTo(leftButton)
        }
        rightButton.onTap = { [weak self] in self?.onTapRight?() }
        rightButton.backgrounds = ButtonTheme.yellowBackgroundDictionary
        rightButton.cornerRadius = ManageAccountsTheme.buttonCornerRadius
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: ManageAccountViewItem, onTapLeft: @escaping () -> (), onTapRight: @escaping () -> ()) {
        switch viewItem.state {
        case .linked(let backedUp):
            roundedBackground.backgroundColor = ManageAccountsTheme.linkedRoundedBackgroundColor
            backedUpIcon.isHidden = backedUp
            leftButton.titleLabel.text = "settings_manage_accounts.unlink".localized
            rightButton.titleLabel.text = "settings_manage_accounts.backup".localized
            configButtonConstraints(both: true)
        case .notLinked(let canCreate):
            roundedBackground.backgroundColor = ManageAccountsTheme.notLinkedRoundedBackgroundColor
            backedUpIcon.isHidden = true
            leftButton.titleLabel.text = "New".localized
            rightButton.titleLabel.text = "Import".localized
            configButtonConstraints(both: canCreate)
        }

        nameLabel.text = viewItem.title.localized
        coinsLabel.text = viewItem.coinCodes

        self.onTapLeft = onTapLeft
        self.onTapRight = onTapRight
    }

    private func configButtonConstraints(both: Bool) {
        if both {
            leftButton.snp.remakeConstraints { maker in
                maker.leading.equalToSuperview().offset(ManageAccountsTheme.cellSmallPadding)
                maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
                maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
            }
            rightButton.snp.remakeConstraints { maker in
                maker.leading.equalTo(leftButton.snp.trailing).offset(ManageAccountsTheme.cellSmallPadding)
                maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
                maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellSmallPadding)
                maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
                maker.width.equalTo(leftButton)
            }
        } else {
            leftButton.snp.remakeConstraints { maker in
                maker.leading.equalToSuperview().offset(ManageAccountsTheme.cellSmallPadding)
                maker.width.equalTo(0)
                maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
                maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
            }
            rightButton.snp.remakeConstraints { maker in
                maker.leading.equalTo(leftButton.snp.trailing)
                maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
                maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellSmallPadding)
                maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
            }
        }
    }

}
