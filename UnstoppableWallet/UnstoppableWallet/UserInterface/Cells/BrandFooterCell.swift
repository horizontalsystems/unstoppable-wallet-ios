import UIKit
import SnapKit
import ThemeKit

class BrandFooterCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin8x
    private static let horizontalPadding: CGFloat = .margin6x
    private static let labelTopMargin: CGFloat = .margin3x
    private static let labelFont: UIFont = .caption

    private static let text = "© Horizontal Systems 2020"

    private let separatorView = UIView()
    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().inset(BrandFooterCell.verticalPadding)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(BrandFooterCell.horizontalPadding)
            maker.top.equalTo(separatorView.snp.top).offset(BrandFooterCell.labelTopMargin)
        }

        label.text = BrandFooterCell.text
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = BrandFooterCell.labelFont
        label.textColor = .themeGray
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension BrandFooterCell {

    static func height(containerWidth: CGFloat) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = text.height(forContainerWidth: textWidth, font: labelFont)

        return verticalPadding + labelTopMargin + textHeight + verticalPadding
    }

}
