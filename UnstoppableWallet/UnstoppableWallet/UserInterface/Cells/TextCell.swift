import UIKit

class TextCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin24
    private static let verticalPadding: CGFloat = .margin12
    private static let font: UIFont = .subhead2

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalPadding)
            maker.top.equalToSuperview().inset(Self.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = Self.font
        label.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var contentText: String? {
        get { label.text }
        set { label.text = newValue }
    }

}

extension TextCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font)
        return textHeight + 2 * verticalPadding
    }

}
