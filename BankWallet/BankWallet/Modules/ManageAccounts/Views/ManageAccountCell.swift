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

    private var onTapCreate: (() -> ())?
    private var onTapRestore: (() -> ())?
    private var onTapUnlink: (() -> ())?
    private var onTapBackup: (() -> ())?

    private var linked: Bool?
    private var rightButtonState: ManageAccountRightButtonState?

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
        rightButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)

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
        guard let linked = linked else {
            return
        }

        if linked {
            onTapUnlink?()
        } else {
            onTapCreate?()
        }
    }

    @objc private func tapRight() {
        guard let buttonState = rightButtonState else {
            return
        }

        switch buttonState {
        case .backup, .show:
            onTapBackup?()
        case .restore:
            onTapRestore?()
        }
    }

    func bind(viewItem: ManageAccountViewItem, onTapCreate: (() -> ())?, onTapRestore: (() -> ())?, onTapUnlink: (() -> ())?, onTapBackup: (() -> ())?) {
        linked = viewItem.linked
        rightButtonState = viewItem.rightButtonState

        let titleText = ManageAccountCell.titleText(viewItem: viewItem)
        let coinsText = viewItem.coinCodes

        if viewItem.linked {
            clippingView.borderWidth = 2 / UIScreen.main.scale
            activeKeyIcon.tintColor = .appJacob

            leftButton.setTitle("settings_manage_keys.delete".localized, for : .normal)
        } else {
            clippingView.borderWidth = 0
            activeKeyIcon.tintColor = .appGray50

            leftButton.setTitle("settings_manage_keys.create".localized, for: .normal)
        }

        switch viewItem.rightButtonState {
        case .backup:
            rightButton.setTitle("settings_manage_keys.backup".localized, for: .normal)
            rightButton.setImage(UIImage(named: "Attention Icon Small")?.tinted(with: .appLucian), for: .normal)
        case .show:
            rightButton.setTitle("settings_manage_keys.show".localized, for: .normal)
            rightButton.setImage(nil, for: .normal)
        case .restore:
            rightButton.setTitle("settings_manage_keys.restore".localized, for: .normal)
            rightButton.setImage(nil, for: .normal)
        }

        accountView.bind(title: titleText, subtitle: coinsText)

        self.onTapCreate = onTapCreate
        self.onTapRestore = onTapRestore
        self.onTapUnlink = onTapUnlink
        self.onTapBackup = onTapBackup
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
