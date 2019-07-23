import UIKit
import SnapKit

class ManageAccountDescriptionCell: UITableViewCell {
    static let descriptionLocalizationKey = "settings_manage_keys.description"

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.textColor = ManageAccountsTheme.descriptionColor
        label.font = ManageAccountsTheme.descriptionFont
        label.numberOfLines = 0
        label.text = ManageAccountDescriptionCell.descriptionLocalizationKey.localized
        label.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leadingMargin.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.bottom.equalToSuperview().offset(-ManageAccountsTheme.cellBottomMargin)
        }
    }

    static func height(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        let view = UIView()
        return ceil(ManageAccountDescriptionCell.descriptionLocalizationKey.localized.height(forContainerWidth: containerWidth - 2 * view.layoutMargins.left, font: ManageAccountsTheme.descriptionFont) + ManageAccountsTheme.cellBottomMargin)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
