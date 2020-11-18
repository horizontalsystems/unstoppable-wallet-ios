import UIKit
import SnapKit
import ThemeKit

class MarkdownBlockQuoteCell: UITableViewCell {
    private static let verticalMargin: CGFloat = .margin3x
    private static let verticalPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin6x

    private let wrapperView = UIView()
    private let textView = MarkdownTextView()
    private let lineView = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview() // constraints are set in bind method
        }

        wrapperView.backgroundColor = .themeSteel10

        wrapperView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(MarkdownBlockQuoteCell.horizontalPadding)
            maker.top.bottom.equalToSuperview().inset(MarkdownBlockQuoteCell.verticalPadding)
        }

        wrapperView.addSubview(lineView)
        lineView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
            maker.width.equalTo(4)
        }

        lineView.backgroundColor = .themeRemus
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(attributedString: NSAttributedString, delegate: UITextViewDelegate?, tightTop: Bool, tightBottom: Bool) {
        textView.attributedText = attributedString
        textView.delegate = delegate

        wrapperView.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().inset(tightTop ? 0 : MarkdownBlockQuoteCell.verticalMargin)
            maker.bottom.equalToSuperview().inset(tightBottom ? 0 : MarkdownBlockQuoteCell.verticalMargin)
        }
    }

}

extension MarkdownBlockQuoteCell {

    static func height(containerWidth: CGFloat, attributedString: NSAttributedString, tightTop: Bool, tightBottom: Bool) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = attributedString.height(containerWidth: textWidth)

        let topMargin = tightTop ? 0 : verticalMargin
        let bottomMargin = tightBottom ? 0 : verticalMargin

        return topMargin + textHeight + 2 * verticalPadding + bottomMargin
    }

}
