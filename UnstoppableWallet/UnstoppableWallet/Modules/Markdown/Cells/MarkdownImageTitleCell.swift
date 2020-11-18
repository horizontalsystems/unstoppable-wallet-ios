import UIKit
import SnapKit
import ThemeKit

class MarkdownImageTitleCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin6x
    private static let labelFont: UIFont = .subhead2

    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(MarkdownImageTitleCell.horizontalPadding)
            maker.top.equalToSuperview().offset(MarkdownImageTitleCell.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = MarkdownImageTitleCell.labelFont
        label.textColor = .themeGray
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String) {
        label.text = text
    }

}

extension MarkdownImageTitleCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = text.height(forContainerWidth: textWidth, font: labelFont)
        return textHeight + 2 * verticalPadding
    }

}
