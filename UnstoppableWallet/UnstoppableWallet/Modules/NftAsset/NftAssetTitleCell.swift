import UIKit
import ComponentKit

class NftAssetTitleCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin16
    private static let font: UIFont = .headline1

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalToSuperview()
        }

        label.numberOfLines = 0
        label.font = Self.font
        label.textColor = .themeLeah
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

}

extension NftAssetTitleCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalMargin
        return text.height(forContainerWidth: textWidth, font: font)
    }

}
