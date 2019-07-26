import UIKit
import SnapKit

class ManageAccountCell: UITableViewCell {
    private let roundedBackground = UIView()
    private let clippingView = UIView()
    private var gradientLayer = CAGradientLayer()

    private let activeKeyIcon = UIImageView()
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

        roundedBackground.backgroundColor = ManageAccountsTheme.roundedBackgroundColor
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

        clippingView.addSubview(activeKeyIcon)
        clippingView.layer.shouldRasterize = true
        clippingView.layer.rasterizationScale = UIScreen.main.scale
        clippingView.borderColor = ManageAccountsTheme.keyImageColor

        gradientLayer.locations = [0.0, 1.0]
        clippingView.layer.addSublayer(gradientLayer)

        activeKeyIcon.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ManageAccountsTheme.cellSmallPadding)
            maker.top.equalToSuperview().offset(ManageAccountsTheme.cellSmallPadding)
        }
        activeKeyIcon.image = UIImage(named: "Key Icon")?.withRenderingMode(.alwaysTemplate)
        activeKeyIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        clippingView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(activeKeyIcon.snp.trailing).offset(ManageAccountsTheme.cellSmallPadding)
            maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellSmallPadding)
            maker.top.equalToSuperview().offset(ManageAccountsTheme.cellSmallPadding)
        }
        nameLabel.font = ManageAccountsTheme.cellTitleFont

        clippingView.addSubview(coinsLabel)
        coinsLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(activeKeyIcon.snp.trailing).offset(ManageAccountsTheme.cellSmallPadding)
            maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.cellSmallPadding)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(ManageAccountsTheme.cellSmallPadding)
        }
        coinsLabel.font = ManageAccountsTheme.coinsFont
        coinsLabel.textColor = ManageAccountsTheme.coinsColor

        clippingView.addSubview(leftButton)
        leftButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ManageAccountsTheme.buttonsMargin)
            maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
            maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
        }
        leftButton.onTap = { [weak self] in self?.onTapLeft?() }
        leftButton.borderWidth = 1 / UIScreen.main.scale
        leftButton.borderColor = ManageAccountsTheme.buttonsBorderColor
        leftButton.borderColor  = ManageAccountsTheme.buttonsBorderColor
        leftButton.backgrounds = ManageAccountsTheme.buttonsBackgroundColorDictionary
        leftButton.textColors = ManageAccountsTheme.buttonsTextColorDictionary
        leftButton.titleLabel.font = ManageAccountsTheme.buttonsFont
        leftButton.cornerRadius = ManageAccountsTheme.buttonCornerRadius

        clippingView.addSubview(rightButton)
        rightButton.snp.makeConstraints { maker in
            maker.leading.equalTo(leftButton.snp.trailing).offset(ManageAccountsTheme.cellSmallPadding)
            maker.top.equalTo(self.coinsLabel.snp.bottom).offset(ManageAccountsTheme.buttonsTopMargin)
            maker.trailing.equalToSuperview().offset(-ManageAccountsTheme.buttonsMargin)
            maker.height.equalTo(ManageAccountsTheme.buttonsHeight)
            maker.width.equalTo(leftButton)
        }
        rightButton.onTap = { [weak self] in self?.onTapRight?() }
        rightButton.borderWidth = 1 / UIScreen.main.scale
        rightButton.borderColor = ManageAccountsTheme.buttonsBorderColor
        rightButton.backgrounds = ManageAccountsTheme.buttonsBackgroundColorDictionary
        rightButton.textColors = ManageAccountsTheme.buttonsTextColorDictionary
        rightButton.titleLabel.font = ManageAccountsTheme.buttonsFont
        rightButton.cornerRadius = ManageAccountsTheme.buttonCornerRadius

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: ManageAccountViewItem, onTapLeft: @escaping () -> (), onTapRight: @escaping () -> ()) {
        let gradientColor: UIColor
        switch viewItem.state {
        case .linked(let backedUp):
            roundedBackground.layer.shadowOpacity = ManageAccountsTheme.roundedBackgroundShadowOpacity
            clippingView.borderWidth = 2 / UIScreen.main.scale

            leftButton.titleLabel.text = "settings_manage_keys.unlink".localized
            rightButton.titleLabel.text = backedUp ? "settings_manage_keys.show".localized : "settings_manage_keys.backup".localized
            rightButton.image = backedUp ? nil : UIImage(named: "Attention Icon Small")?.tinted(with: ManageAccountsTheme.attentionColor)

            activeKeyIcon.tintColor = ManageAccountsTheme.keyImageColor
            nameLabel.textColor = ManageAccountsTheme.cellTitleColor
            coinsLabel.textColor = ManageAccountsTheme.coinsColor

            gradientColor = ManageAccountsTheme.gradientRoundedBackgroundColor ?? UIColor.clear
        case .notLinked:
            roundedBackground.layer.shadowOpacity = 0
            clippingView.borderWidth = 0

            leftButton.titleLabel.text = "settings_manage_keys.create".localized
            rightButton.titleLabel.text = "settings_manage_keys.restore".localized
            rightButton.image = nil

            activeKeyIcon.tintColor = ManageAccountsTheme.nonActiveKeyImageColor
            nameLabel.textColor = ManageAccountsTheme.nonActiveCellColor
            coinsLabel.textColor = ManageAccountsTheme.nonActiveCellColor

            gradientColor = .clear
        }

        gradientLayer.colors = [gradientColor.cgColor, UIColor.clear.cgColor]

        nameLabel.text = viewItem.title.localized
        coinsLabel.text = viewItem.coinCodes.localized

        self.onTapLeft = onTapLeft
        self.onTapRight = onTapRight
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
    }

}
