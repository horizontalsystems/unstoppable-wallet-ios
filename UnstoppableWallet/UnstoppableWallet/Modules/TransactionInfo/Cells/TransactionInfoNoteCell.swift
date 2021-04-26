import UIKit
import ThemeKit
import ComponentKit

class TransactionInfoNoteCell: BaseThemeCell {
    private static let imageViewLeadingMargin: CGFloat = .margin4x
    private static let imageViewSize: CGFloat = 20
    private static let labelHorizontalMargin: CGFloat = .margin4x
    private static let labelVerticalMargin: CGFloat = 13.5
    private static let labelFont: UIFont = .subhead2

    private let iconImageView = UIImageView()
    private let label = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoNoteCell.imageViewLeadingMargin)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.size.equalTo(TransactionInfoNoteCell.imageViewSize)
        }

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(TransactionInfoNoteCell.labelHorizontalMargin)
            maker.top.equalToSuperview().offset(TransactionInfoNoteCell.labelVerticalMargin)
            maker.trailing.equalToSuperview().inset(TransactionInfoNoteCell.labelHorizontalMargin)
        }

        label.numberOfLines = 0
        label.font = TransactionInfoNoteCell.labelFont
        label.textColor = .themeGray
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(image: UIImage?, imageTintColor: UIColor?, text: String) {
        iconImageView.image = image
        iconImageView.tintColor = imageTintColor
        label.text = text
    }

}

extension TransactionInfoNoteCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textWidth = containerWidth - imageViewLeadingMargin - imageViewSize - 2 * labelHorizontalMargin
        let textHeight = text.height(forContainerWidth: textWidth, font: labelFont)

        return textHeight + 2 * labelVerticalMargin
    }

}
