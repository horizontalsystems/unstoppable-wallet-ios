import UIKit
import SnapKit
import ThemeKit

class GuideTextCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin6x

    private let textView = GuideTextView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(GuideTextCell.horizontalPadding)
            maker.top.bottom.equalToSuperview().inset(GuideTextCell.verticalPadding)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(attributedString: NSAttributedString, delegate: UITextViewDelegate?) {
        textView.attributedText = attributedString
        textView.delegate = delegate
    }

}

extension GuideTextCell {

    static func height(containerWidth: CGFloat, attributedString: NSAttributedString) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = attributedString.height(containerWidth: textWidth)

        return textHeight + 2 * verticalPadding
    }

}
