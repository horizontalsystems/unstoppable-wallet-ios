import UIKit
import SnapKit

class ManageAccountDescriptionCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.textColor = ManageAccountsTheme.descriptionColor
        label.font = ManageAccountsTheme.descriptionFont
        label.numberOfLines = 0
        label.text = "settings_manage_keys.description".localized
        label.snp.makeConstraints { maker in
            maker.top.equalToSuperview()//.offset(ManageAccountsTheme.cellBigPadding)
            maker.leadingMargin.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.bottom.equalToSuperview().offset(-ManageAccountsTheme.cellBottomMargin)
        }
    }

    static func height(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        let view = UIView()
        return ceil("settings_manage_keys.description".localized.height(forContainerWidth: containerWidth - 2 * view.layoutMargins.left, font: ManageAccountsTheme.descriptionFont) + ManageAccountsTheme.cellBottomMargin)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
