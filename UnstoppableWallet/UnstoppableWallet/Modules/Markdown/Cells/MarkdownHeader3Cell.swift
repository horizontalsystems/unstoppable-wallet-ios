import UIKit
import SnapKit
import ThemeKit

class MarkdownHeader3Cell: UITableViewCell {
    private static let topPadding: CGFloat = .margin6x
    private static let bottomPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin6x

    private let textView = MarkdownTextView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(MarkdownHeader3Cell.horizontalPadding)
            maker.top.equalToSuperview().inset(MarkdownHeader3Cell.topPadding)
            maker.bottom.equalToSuperview().inset(MarkdownHeader3Cell.bottomPadding)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(attributedString: NSAttributedString) {
        textView.attributedText = attributedString
    }

}

extension MarkdownHeader3Cell {

    static func height(containerWidth: CGFloat, attributedString: NSAttributedString) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = attributedString.height(containerWidth: textWidth)

        return topPadding + textHeight + bottomPadding
    }

}
