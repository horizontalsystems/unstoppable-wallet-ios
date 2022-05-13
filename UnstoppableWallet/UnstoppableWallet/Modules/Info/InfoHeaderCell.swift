import UIKit

class InfoHeaderCell: UITableViewCell {
    private static let topPadding = CGFloat.margin16
    private static let bottomPadding = CGFloat.margin4
    private static let horizontalPadding = CGFloat.margin24
    private static let font: UIFont = .headline2

    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(InfoHeaderCell.horizontalPadding)
            maker.top.equalToSuperview().inset(InfoHeaderCell.topPadding)
        }

        label.numberOfLines = 0
        label.font = InfoHeaderCell.font
        label.textColor = .themeJacob
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(string: String?) {
        label.text = string
    }

}

extension InfoHeaderCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font)
        return textHeight + topPadding + bottomPadding
    }

}
