import UIKit
import SnapKit

class ManageAccountDescriptionCell: UITableViewCell {
    static let topMargin: CGFloat = .margin3x
    static let bottomMargin: CGFloat = .margin2x
    static let sideMargin: CGFloat = .margin6x
    static let descriptionFont: UIFont = .appSubhead2

    static var descriptionText: String {
        "settings_manage_keys.description".localized
    }

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.textColor = .appGray
        label.font = ManageAccountDescriptionCell.descriptionFont
        label.numberOfLines = 0
        label.text = ManageAccountDescriptionCell.descriptionText
        label.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(ManageAccountDescriptionCell.topMargin)
            maker.leading.trailing.equalToSuperview().inset(ManageAccountDescriptionCell.sideMargin)
            maker.bottom.equalToSuperview().inset(ManageAccountDescriptionCell.bottomMargin)
        }
    }

    static func height(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        ManageAccountDescriptionCell.descriptionText.height(forContainerWidth: containerWidth - 2 * ManageAccountDescriptionCell.sideMargin, font: ManageAccountDescriptionCell.descriptionFont) + ManageAccountDescriptionCell.topMargin + ManageAccountDescriptionCell.bottomMargin
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
