import UIKit
import SnapKit
import ThemeKit

class MarkdownHeader1Cell: UITableViewCell {
    private static let topPadding: CGFloat = .margin6x
    private static let bottomPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin6x
    private static let separatorHeight: CGFloat = .heightOnePixel
    private static let separatorTopMargin: CGFloat = .margin2x

    private let textView = MarkdownTextView()
    private let separatorView = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(MarkdownHeader1Cell.horizontalPadding)
            maker.top.equalToSuperview().inset(MarkdownHeader1Cell.topPadding)
        }

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(MarkdownHeader1Cell.horizontalPadding)
            maker.top.equalTo(textView.snp.bottom).offset(MarkdownHeader1Cell.separatorTopMargin)
            maker.bottom.equalToSuperview().inset(MarkdownHeader1Cell.bottomPadding)
            maker.height.equalTo(MarkdownHeader1Cell.separatorHeight)
        }

        separatorView.backgroundColor = .themeGray50
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(attributedString: NSAttributedString) {
        textView.attributedText = attributedString
    }

}

extension MarkdownHeader1Cell {

    static func height(containerWidth: CGFloat, attributedString: NSAttributedString) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = attributedString.height(containerWidth: textWidth)

        return topPadding + textHeight + separatorTopMargin + separatorHeight + bottomPadding
    }

}
