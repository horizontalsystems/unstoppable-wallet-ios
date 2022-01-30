import UIKit
import ComponentKit

class NftAssetTitleCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin12
    private static let middleVerticalMargin: CGFloat = .margin12
    private static let titleFont: UIFont = .headline1
    private static let subtitleFont: UIFont = .subhead1

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalToSuperview()
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = Self.titleFont
        titleLabel.textColor = .themeLeah

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalTo(titleLabel.snp.bottom).offset(Self.middleVerticalMargin)
        }

        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = Self.subtitleFont
        subtitleLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

}

extension NftAssetTitleCell {

    static func height(containerWidth: CGFloat, title: String, subtitle: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalMargin

        let titleHeight = title.height(forContainerWidth: textWidth, font: titleFont)
        let subtitleHeight = subtitle.height(forContainerWidth: textWidth, font: subtitleFont)

        return titleHeight + middleVerticalMargin + subtitleHeight
    }

}
