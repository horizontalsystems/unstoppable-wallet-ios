import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class DonateCell: BaseThemeCell {
    private static let verticalPadding: CGFloat = .margin32
    private static let iconWrapperSize: CGFloat = 100
    private static let contentWidth: CGFloat = 264
    private static let textFont: UIFont = .headline2

    private let iconImageView = UIImageView()
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().inset(Self.verticalPadding)
            maker.size.equalTo(Self.iconWrapperSize)
        }

        iconImageView.contentMode = .center
        iconImageView.cornerRadius = Self.iconWrapperSize / 2
        iconImageView.backgroundColor = .themeSteel10

        wrapperView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(iconImageView.snp.bottom).offset(Self.verticalPadding)
            maker.width.equalTo(Self.contentWidth)
        }

        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Self.textFont
        label.textColor = .themeLeah
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(icon: UIImage?, text: String) {
        iconImageView.image = icon
        label.text = text
    }

}

extension DonateCell {

    static func height(text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: contentWidth, font: textFont)
        return verticalPadding + iconWrapperSize + verticalPadding + textHeight + verticalPadding
    }

}
