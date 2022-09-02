import UIKit

class DescriptionCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin32
    private static let verticalPadding: CGFloat = .margin12
    private static let font: UIFont = .body

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(DescriptionCell.horizontalPadding)
            maker.top.equalToSuperview().inset(DescriptionCell.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = DescriptionCell.font
        label.textColor = .themeBran
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text
    }

}

extension DescriptionCell {

    static func height(containerWidth: CGFloat, text: String, ignoreBottomMargin: Bool = false) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font)
        return textHeight + (ignoreBottomMargin ? 1 : 2) * verticalPadding
    }

}
