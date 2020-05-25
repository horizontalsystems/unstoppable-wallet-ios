import UIKit

class PrivacyHeaderCell: UITableViewCell {
    private static let sideMargin: CGFloat = .margin4x
    private static let topMargin: CGFloat = .margin3x
    private static let bottomMargin: CGFloat = .margin6x

    private static var description: String { "settings_privacy.header_description".localized }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        let descriptionView = HighlightedDescriptionView()

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(PrivacyHeaderCell.sideMargin)
            maker.top.equalToSuperview().offset(PrivacyHeaderCell.topMargin)
            maker.bottom.equalToSuperview().inset(PrivacyHeaderCell.bottomMargin)
        }

        descriptionView.bind(text: PrivacyHeaderCell.description)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func height(containerWidth: CGFloat) -> CGFloat {
        let descriptionViewWidth = containerWidth - 2 * sideMargin
        let descriptionViewHeight = HighlightedDescriptionView.height(containerWidth: descriptionViewWidth, text: PrivacyHeaderCell.description)
        return topMargin + descriptionViewHeight + bottomMargin
    }

}
