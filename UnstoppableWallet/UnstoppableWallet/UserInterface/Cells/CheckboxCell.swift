import UIKit
import ThemeKit

class CheckboxCell: UITableViewCell {
    private static let imageViewLeadingMargin: CGFloat = .margin6x
    private static let imageViewSize: CGFloat = 24
    private static let textLeadingMargin: CGFloat = .margin4x
    private static let textTrailingMargin: CGFloat = .margin6x
    private static let textVerticalMargin: CGFloat = .margin4x
    private static let textFont: UIFont = .subhead2

    private let checkBoxImageView = UIImageView()
    private let descriptionLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(checkBoxImageView)
        checkBoxImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CheckboxCell.imageViewLeadingMargin)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.size.equalTo(CheckboxCell.imageViewSize)
        }

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(checkBoxImageView.snp.trailing).offset(CheckboxCell.textLeadingMargin)
            maker.top.equalToSuperview().inset(CheckboxCell.textVerticalMargin)
            maker.trailing.equalToSuperview().inset(CheckboxCell.textTrailingMargin)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = CheckboxCell.textFont
        descriptionLabel.textColor = .themeOz
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?, checked: Bool) {
        descriptionLabel.text = text
        checkBoxImageView.image = UIImage(named: checked ? "Checkbox Checked" : "Checkbox Unchecked")
    }

}

extension CheckboxCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textWidth = containerWidth - imageViewLeadingMargin - imageViewSize - textLeadingMargin - textTrailingMargin
        let textHeight = text.height(forContainerWidth: textWidth, font: textFont)

        return textHeight + 2 * textVerticalMargin
    }

}
