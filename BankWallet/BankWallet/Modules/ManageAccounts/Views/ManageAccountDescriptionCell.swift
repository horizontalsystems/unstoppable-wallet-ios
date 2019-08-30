import UIKit
import SnapKit

class ManageAccountDescriptionCell: UITableViewCell {
    static var descriptionText: String {
        return "settings_manage_keys.description".localized
    }

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.textColor = ManageAccountsTheme.descriptionColor
        label.font = ManageAccountsTheme.descriptionFont
        label.numberOfLines = 0
        label.text = ManageAccountDescriptionCell.descriptionText
        label.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(ManageAccountsTheme.cellBottomMargin)
            maker.leading.trailing.equalToSuperview().inset(AppTheme.viewMargin)
            maker.bottom.equalToSuperview().offset(-ManageAccountsTheme.cellBottomMargin)
        }
    }

    static func height(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        return ManageAccountDescriptionCell.descriptionText.height(forContainerWidth: containerWidth - 2 * AppTheme.viewMargin, font: ManageAccountsTheme.descriptionFont) + ManageAccountsTheme.cellTopMargin + ManageAccountsTheme.cellBottomMargin
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
