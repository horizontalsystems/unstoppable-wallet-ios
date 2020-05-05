import UIKit

class PrivacyInfoCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin6x
    private static let verticalPadding: CGFloat = .margin3x
    private static let font: UIFont = .subhead2

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(PrivacyInfoCell.horizontalPadding)
            maker.top.equalToSuperview().inset(PrivacyInfoCell.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = PrivacyInfoCell.font
        label.textColor = .themeLeah
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text
    }

}

extension PrivacyInfoCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font)
        return textHeight + 2 * verticalPadding
    }

}
