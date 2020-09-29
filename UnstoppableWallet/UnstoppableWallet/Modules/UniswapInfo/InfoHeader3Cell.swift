import UIKit
import SnapKit
import ThemeKit

class InfoHeader3Cell: UITableViewCell {
    private static let topPadding: CGFloat = .margin6x
    private static let horizontalPadding: CGFloat = .margin6x
    private static let separatorHeight: CGFloat = .heightOnePixel
    private static let separatorTopMargin: CGFloat = .margin2x

    private static let font: UIFont = .title3

    private let label = UILabel()
    private let separatorView = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(InfoHeader3Cell.horizontalPadding)
            maker.top.equalToSuperview().inset(InfoHeader3Cell.topPadding)
        }

        label.font = .title3
        label.textColor = .themeJacob

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(InfoHeader3Cell.horizontalPadding)
            maker.top.equalTo(label.snp.bottom).offset(InfoHeader3Cell.separatorTopMargin)
            maker.height.equalTo(InfoHeader3Cell.separatorHeight)
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

extension InfoHeader3Cell {

    static func height(containerWidth: CGFloat, string: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = string.height(forContainerWidth: textWidth, font: InfoHeader3Cell.font)

        return topPadding + textHeight + separatorTopMargin + separatorHeight
    }

}
