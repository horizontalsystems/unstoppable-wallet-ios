import UIKit
import SnapKit

class ManageAccountCell: CardCell {
    private static let topPadding: CGFloat = .margin2x
    private static let bottomPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin3x
    private static let keyIconRightMargin: CGFloat = .margin2x
    private static let accountViewTopPadding: CGFloat = 10
    private static let buttonHeight: CGFloat = .heightButtonSecondary
    private static let buttonTopMargin: CGFloat = .margin3x

    private let accountView = AccountDoubleLineCellView()
    private let activeKeyIcon = UIImageView()
    private let leftButton = UIButton.appSecondary
    private let rightButton = UIButton.appSecondary

    private var onTapLeft: (() -> ())?
    private var onTapRight: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        clippingView.layer.shouldRasterize = true
        clippingView.layer.rasterizationScale = UIScreen.main.scale
        clippingView.borderColor = .appJacob

        activeKeyIcon.image = UIImage(named: "Key Icon")?.withRenderingMode(.alwaysTemplate)
        activeKeyIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        clippingView.addSubview(activeKeyIcon)
        activeKeyIcon.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ManageAccountCell.horizontalPadding)
            maker.top.equalToSuperview().offset(ManageAccountCell.topPadding)
        }

        clippingView.addSubview(accountView)
        accountView.snp.makeConstraints { maker in
            maker.leading.equalTo(activeKeyIcon.snp.trailing).offset(ManageAccountCell.keyIconRightMargin)
            maker.trailing.equalToSuperview().inset(ManageAccountCell.horizontalPadding)
            maker.top.equalToSuperview().offset(ManageAccountCell.accountViewTopPadding)
        }

        leftButton.addTarget(self, action: #selector(tapLeft), for: .touchUpInside)

        clippingView.addSubview(leftButton)
        leftButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalTo(accountView.snp.bottom).offset(ManageAccountCell.buttonTopMargin)
            maker.height.equalTo(CGFloat.heightButtonSecondary)
            maker.bottom.equalToSuperview().inset(ManageAccountCell.bottomPadding)
        }

        rightButton.addTarget(self, action: #selector(tapRight), for: .touchUpInside)

        clippingView.addSubview(rightButton)
        rightButton.snp.makeConstraints { maker in
            maker.leading.equalTo(leftButton.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalTo(accountView.snp.bottom).offset(ManageAccountCell.buttonTopMargin)
            maker.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.height.equalTo(CGFloat.heightButtonSecondary)
            maker.width.equalTo(leftButton)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc private func tapLeft() {
        onTapLeft?()
    }

    @objc private func tapRight() {
        onTapRight?()
    }

    func bind(viewItem: ManageAccountViewItem, onTapLeft: @escaping () -> (), onTapRight: @escaping () -> ()) {
        let titleText = ManageAccountCell.titleText(viewItem: viewItem)
        let coinsText = viewItem.coinCodes

        switch viewItem.state {
        case .linked(let backedUp):
            clippingView.borderWidth = 2 / UIScreen.main.scale
            activeKeyIcon.tintColor = .appJacob

            leftButton.setTitle("settings_manage_keys.delete".localized, for: .normal)
            rightButton.setTitle(backedUp ? "settings_manage_keys.show".localized : "settings_manage_keys.backup".localized, for: .normal)
            rightButton.setImage(backedUp ? nil : UIImage(named: "Attention Icon Small")?.tinted(with: ManageAccountsTheme.attentionColor), for: .normal)
            rightButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)

            accountView.bind(title: titleText, subtitle: coinsText)
        case .notLinked:
            clippingView.borderWidth = 0
            activeKeyIcon.tintColor = .appGray50

            leftButton.setTitle("settings_manage_keys.create".localized, for: .normal)
            rightButton.setTitle("settings_manage_keys.restore".localized, for: .normal)
            rightButton.setImage(nil, for: .normal)

            accountView.bind(title: titleText, subtitle: coinsText)
        }

        self.onTapLeft = onTapLeft
        self.onTapRight = onTapRight
    }

}

extension ManageAccountCell {

    static func titleText(viewItem: ManageAccountViewItem) -> String {
        "settings_manage_keys.item_title".localized(viewItem.title)
    }

    static func height(containerWidth: CGFloat, viewItem: ManageAccountViewItem) -> CGFloat {
        let iconWidth = UIImage(named: "Key Icon")?.size.width ?? 0
        let contentWidth = CardCell.contentWidth(containerWidth: containerWidth) - ManageAccountCell.horizontalPadding * 2 - ManageAccountCell.keyIconRightMargin - iconWidth
        let accountViewHeight = AccountDoubleLineCellView.height(containerWidth: contentWidth, title: ManageAccountCell.titleText(viewItem: viewItem), subtitle: viewItem.coinCodes)

        let contentHeight = accountViewHeight + ManageAccountCell.accountViewTopPadding + ManageAccountCell.buttonTopMargin + ManageAccountCell.buttonHeight + ManageAccountCell.bottomPadding
        return CardCell.height(contentHeight: contentHeight)
    }

}
