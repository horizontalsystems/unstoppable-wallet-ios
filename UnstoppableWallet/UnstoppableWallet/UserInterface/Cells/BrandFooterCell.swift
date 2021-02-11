import UIKit
import SnapKit
import ThemeKit

class BrandFooterCell: UITableViewCell {
    static let brandText = "© Horizontal Systems 2021"

    private static let topPadding: CGFloat = .margin12
    private static let bottomPadding: CGFloat = .margin32
    private static let horizontalPadding: CGFloat = .margin24
    private static let labelFont: UIFont = .caption

    private let separatorView = UIView()
    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(BrandFooterCell.horizontalPadding)
            maker.top.equalTo(separatorView.snp.top).offset(BrandFooterCell.topPadding)
        }

        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = BrandFooterCell.labelFont
        label.textColor = .themeGray
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

}

extension BrandFooterCell {

    static func height(containerWidth: CGFloat, title: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = title.height(forContainerWidth: textWidth, font: labelFont)

        return topPadding + textHeight + bottomPadding
    }

}
