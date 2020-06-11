import UIKit
import SnapKit
import ThemeKit

class GuideFooterCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin8x
    private static let horizontalPadding: CGFloat = .margin6x
    private static let labelTopMargin: CGFloat = .margin3x
    private static let labelFont: UIFont = .caption

    private let separatorView = UIView()
    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().inset(GuideFooterCell.verticalPadding)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeGray50

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(GuideFooterCell.horizontalPadding)
            maker.top.equalTo(separatorView.snp.top).offset(GuideFooterCell.labelTopMargin)
        }

        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = GuideFooterCell.labelFont
        label.textColor = .themeGray
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String) {
        label.text = text
    }

}

extension GuideFooterCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = text.height(forContainerWidth: textWidth, font: labelFont)

        return verticalPadding + labelTopMargin + textHeight + verticalPadding
    }

}
