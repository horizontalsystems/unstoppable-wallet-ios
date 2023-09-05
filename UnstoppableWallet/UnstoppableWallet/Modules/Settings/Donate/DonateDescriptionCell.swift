import UIKit

class DonateDescriptionCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin32
    private static let verticalPadding: CGFloat = .margin24
    private static let labelFont: UIFont = .headline2
    private static let emojiFont: UIFont = .title3

    let label = UILabel()
    let emoji = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(DonateDescriptionCell.horizontalPadding)
            maker.top.equalToSuperview().inset(DonateDescriptionCell.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = DonateDescriptionCell.labelFont
        label.textColor = .themeLeah
        label.textAlignment = .center

        contentView.addSubview(emoji)
        emoji.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(DonateDescriptionCell.horizontalPadding)
            maker.top.equalTo(label.snp.bottom).offset(DonateDescriptionCell.verticalPadding)
        }

        emoji.font = DonateDescriptionCell.emojiFont
        emoji.textColor = .themeLeah
        emoji.text = "🙏"
        emoji.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension DonateDescriptionCell {

    static func height(containerWidth: CGFloat, text: String, font: UIFont? = nil, ignoreBottomMargin: Bool = false) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font ?? Self.labelFont)
        let emojiHeight = "🙏".height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font ?? Self.labelFont)
        return textHeight + .margin24 + emojiHeight + (ignoreBottomMargin ? 1 : 2) * verticalPadding
    }

}
