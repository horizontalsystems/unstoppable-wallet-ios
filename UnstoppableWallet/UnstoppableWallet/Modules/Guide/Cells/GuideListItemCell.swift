import UIKit
import SnapKit
import ThemeKit

class GuideListItemCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin6x
    private static let prefixWidth: CGFloat = .margin6x

    private let prefixLabel = UILabel()
    private let textView = GuideTextView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(prefixLabel)
        prefixLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(GuideListItemCell.horizontalPadding)
            maker.top.equalToSuperview()
        }

        prefixLabel.font = .body
        prefixLabel.textColor = .themeOz

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.equalTo(prefixLabel.snp.leading).offset(GuideListItemCell.prefixWidth)
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview().inset(GuideListItemCell.horizontalPadding)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(prefix: String, attributedString: NSAttributedString) {
        prefixLabel.text = prefix
        textView.attributedText = attributedString
    }

}

extension GuideListItemCell {

    static func height(containerWidth: CGFloat, attributedString: NSAttributedString) -> CGFloat {
        let textWidth = containerWidth - prefixWidth - 2 * horizontalPadding
        let textHeight = attributedString.height(containerWidth: textWidth)

        return textHeight
    }

}
