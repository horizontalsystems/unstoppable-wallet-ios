import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class CoinPageInfoCell: UITableViewCell {
    private static let titleHeight: CGFloat = .heightSingleLineCell
    private static let descriptionInsets = UIEdgeInsets(top: .margin12, left: .margin24, bottom: .margin24, right: .margin24)
    private static let descriptionFont: UIFont = .body

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalToSuperview()
            maker.height.equalTo(Self.titleHeight)
        }

        titleLabel.font = .headline2

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(Self.descriptionInsets)
            maker.top.equalTo(titleLabel.snp.bottom)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = Self.descriptionFont
        descriptionLabel.textColor = .themeBran
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: CoinDetailsViewModel.SecurityInfoViewItem) {
        titleLabel.text = viewItem.title
        titleLabel.textColor = viewItem.grade.color
        descriptionLabel.text = viewItem.text
    }

}

extension CoinPageInfoCell {

    static func height(containerWidth: CGFloat, description: String) -> CGFloat {
        let descriptionWidth = containerWidth - descriptionInsets.width
        let descriptionHeight = description.height(forContainerWidth: descriptionWidth, font: descriptionFont)

        return titleHeight + descriptionHeight + descriptionInsets.height
    }

}
