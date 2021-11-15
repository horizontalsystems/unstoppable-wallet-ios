import UIKit
import ThemeKit
import ComponentKit

class CheckboxCell: BaseSelectableThemeCell {
    private static let checkBoxLeadingMargin: CGFloat = .margin16
    private static let checkBoxSize: CGFloat = 24
    private static let textLeadingMargin: CGFloat = .margin16
    private static let textTrailingMargin: CGFloat = .margin16
    private static let textVerticalMargin: CGFloat = .margin16
    private static let textFont: UIFont = .subhead2

    private let checkBoxView = UIView()
    private let checkBoxImageView = UIImageView()
    private let descriptionLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        wrapperView.addSubview(checkBoxView)
        checkBoxView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CheckboxCell.checkBoxLeadingMargin)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(CheckboxCell.checkBoxSize)
        }

        checkBoxView.layer.cornerRadius = .cornerRadius4
        checkBoxView.layer.borderColor = UIColor.themeGray.cgColor
        checkBoxView.layer.borderWidth = .heightOneDp + .heightOnePixel

        checkBoxView.addSubview(checkBoxImageView)
        checkBoxImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        checkBoxImageView.image = UIImage(named: "check_2_20")?.withRenderingMode(.alwaysTemplate)
        checkBoxImageView.tintColor = .themeJacob

        wrapperView.addSubview(descriptionLabel)
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

    func bind(text: String?, checked: Bool, backgroundStyle: BackgroundStyle, isFirst: Bool = false, isLast: Bool = false) {
        set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
        descriptionLabel.text = text

        checkBoxImageView.isHidden = !checked
    }

}

extension CheckboxCell {

    static func height(containerWidth: CGFloat, text: String, backgroundStyle: BackgroundStyle) -> CGFloat {
        let textWidth = containerWidth - Self.margin(backgroundStyle: backgroundStyle).width - checkBoxLeadingMargin - checkBoxSize - textLeadingMargin - textTrailingMargin
        let textHeight = text.height(forContainerWidth: textWidth, font: textFont)

        return textHeight + 2 * textVerticalMargin
    }

}
