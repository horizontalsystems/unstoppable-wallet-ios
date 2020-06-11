import UIKit
import SnapKit
import ThemeKit

class GuideBlockQuoteCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin6x

    private let textView = GuideTextView()
    private let lineView = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .themeJeremy

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(GuideBlockQuoteCell.horizontalPadding)
            maker.top.bottom.equalToSuperview().inset(GuideBlockQuoteCell.verticalPadding)
        }

        contentView.addSubview(lineView)
        lineView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
            maker.width.equalTo(4)
        }

        lineView.backgroundColor = .themeGreen50
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(attributedString: NSAttributedString) {
        textView.attributedText = attributedString
    }

}

extension GuideBlockQuoteCell {

    static func height(containerWidth: CGFloat, attributedString: NSAttributedString) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = attributedString.height(containerWidth: textWidth)

        return textHeight + 2 * verticalPadding
    }

}
