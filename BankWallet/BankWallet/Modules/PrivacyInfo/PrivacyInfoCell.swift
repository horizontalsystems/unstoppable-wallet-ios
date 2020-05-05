import UIKit

class PrivacyInfoCell: UITableViewCell {
    private static let sidePadding: CGFloat = .margin6x
    private static let verticalPadding: CGFloat = .margin3x
    private static let font: UIFont = .subhead2

    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(PrivacyInfoCell.sidePadding)
            maker.top.bottom.equalToSuperview().inset(PrivacyInfoCell.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = PrivacyInfoCell.font
        label.textColor = .themeLeah
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func bind(text: String?) {
        label.text = text
    }

}

extension PrivacyInfoCell {

    public static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * sidePadding, font: font)
        return textHeight + 2 * verticalPadding
    }

}
