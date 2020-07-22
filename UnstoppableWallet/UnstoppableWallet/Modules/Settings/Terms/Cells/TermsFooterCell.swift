import UIKit
import SnapKit
import ThemeKit

class TermsFooterCell: UITableViewCell {
    private static let topPadding: CGFloat = .margin8x
    private static let horizontalPadding: CGFloat = 80
    private static let textFont: UIFont = .title3

    private static var text: String {
        "terms.footer".localized
    }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        let label = UILabel()

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(TermsFooterCell.horizontalPadding)
            maker.top.equalToSuperview().offset(TermsFooterCell.topPadding)
        }

        label.text = TermsFooterCell.text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = TermsFooterCell.textFont
        label.textColor = .themeJacob
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

extension TermsFooterCell {

    static func height(containerWidth: CGFloat) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = text.height(forContainerWidth: textWidth, font: textFont)

        return topPadding + textHeight
    }

}
