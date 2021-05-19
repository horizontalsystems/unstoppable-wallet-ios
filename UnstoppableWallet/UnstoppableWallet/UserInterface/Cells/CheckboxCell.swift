import UIKit
import ThemeKit

class CheckboxCell: UITableViewCell {
    private static let checkBoxLeadingMargin: CGFloat = .margin6x
    private static let checkBoxSize: CGFloat = 24
    private static let textLeadingMargin: CGFloat = .margin4x
    private static let textTrailingMargin: CGFloat = .margin6x
    private static let textVerticalMargin: CGFloat = .margin4x
    private static let textFont: UIFont = .subhead2

    private let checkBoxView = UIView()
    private let checkBoxImageView = UIImageView()
    private let descriptionLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(checkBoxView)
        checkBoxView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CheckboxCell.checkBoxLeadingMargin)
            maker.top.equalToSuperview().offset(CGFloat.margin12)
            maker.size.equalTo(CheckboxCell.checkBoxSize)
        }

        checkBoxView.layer.cornerRadius = .cornerRadius4
        checkBoxView.layer.borderColor = UIColor.themeGray.cgColor

        checkBoxView.addSubview(checkBoxImageView)
        checkBoxImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        checkBoxImageView.image = UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate)
        checkBoxImageView.tintColor = .themeWhite

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(checkBoxView.snp.trailing).offset(CheckboxCell.textLeadingMargin)
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

        checkBoxView.layer.borderWidth = checked ? 0 : 2
        checkBoxView.backgroundColor = checked ? .themeRemus : .clear
        checkBoxImageView.isHidden = !checked
    }

}

extension CheckboxCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textWidth = containerWidth - checkBoxLeadingMargin - checkBoxSize - textLeadingMargin - textTrailingMargin
        let textHeight = text.height(forContainerWidth: textWidth, font: textFont)

        return textHeight + 2 * textVerticalMargin
    }

}
