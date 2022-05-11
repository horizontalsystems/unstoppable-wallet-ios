import UIKit
import SnapKit
import ThemeKit

class InfoHeader2Cell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin12
    private static let horizontalPadding: CGFloat = .margin24
    private static let separatorHeight: CGFloat = .heightOnePixel
    private static let separatorTopMargin: CGFloat = .margin8

    private static let font: UIFont = .title2

    private let label = UILabel()
    private let separatorView = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(InfoHeader2Cell.horizontalPadding)
            maker.top.equalToSuperview().inset(InfoHeader2Cell.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = Self.font
        label.textColor = .themeLeah

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(InfoHeader2Cell.horizontalPadding)
            maker.top.equalTo(label.snp.bottom).offset(InfoHeader2Cell.separatorTopMargin)
            maker.height.equalTo(InfoHeader2Cell.separatorHeight)
        }

        separatorView.backgroundColor = .themeGray50
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(string: String) {
        label.text = string
    }

}

extension InfoHeader2Cell {

    static func height(containerWidth: CGFloat, string: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = string.height(forContainerWidth: textWidth, font: InfoHeader2Cell.font)

        return verticalPadding + textHeight + separatorTopMargin + separatorHeight + verticalPadding
    }

}
