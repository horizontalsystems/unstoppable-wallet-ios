import UIKit
import SnapKit
import ThemeKit

class MarkdownListItemCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin6x
    private static let verticalPadding: CGFloat = .margin3x
    private static let tightVerticalPadding: CGFloat = .margin1x
    private static let prefixWidth: CGFloat = .margin6x

    private let wrapperView = UIView()
    private let prefixLabel = UILabel()
    private let textView = MarkdownTextView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview() // constraints are set in bind method
        }

        wrapperView.addSubview(prefixLabel)
        prefixLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(MarkdownListItemCell.horizontalPadding)
            maker.top.equalToSuperview()
        }

        prefixLabel.font = .body
        prefixLabel.textColor = .themeLeah

        wrapperView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.equalTo(prefixLabel.snp.leading).offset(MarkdownListItemCell.prefixWidth)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().inset(MarkdownListItemCell.horizontalPadding)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(attributedString: NSAttributedString, delegate: UITextViewDelegate?, prefix: String?, tightTop: Bool, tightBottom: Bool) {
        prefixLabel.text = prefix
        textView.attributedText = attributedString
        textView.delegate = delegate

        wrapperView.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().inset(tightTop ? MarkdownListItemCell.tightVerticalPadding : MarkdownListItemCell.verticalPadding)
            maker.bottom.equalToSuperview().inset(tightBottom ? MarkdownListItemCell.tightVerticalPadding : MarkdownListItemCell.verticalPadding)
        }
    }

}

extension MarkdownListItemCell {

    static func height(containerWidth: CGFloat, attributedString: NSAttributedString, tightTop: Bool, tightBottom: Bool) -> CGFloat {
        let textWidth = containerWidth - prefixWidth - 2 * horizontalPadding
        let textHeight = attributedString.height(containerWidth: textWidth)
        let topPadding = tightTop ? tightVerticalPadding : verticalPadding
        let bottomPadding = tightBottom ? tightVerticalPadding : verticalPadding

        return topPadding + textHeight + bottomPadding
    }

}
