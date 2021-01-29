import UIKit
import ThemeKit
import SnapKit

class FilterCard: UICollectionViewCell {
    static let titleFont: UIFont = .subhead1
    static let sideMargin: CGFloat = .margin12

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.cornerRadius = .margin16

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(FilterCard.sideMargin)
            maker.top.equalToSuperview().inset(FilterCard.sideMargin)
        }

        titleLabel.font = FilterCard.titleFont

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(FilterCard.sideMargin)
            maker.bottom.equalToSuperview().inset(FilterCard.sideMargin)
        }

        descriptionLabel.font = .caption
        titleLabel.textColor = .themeDark

        bind(selected: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            bind(selected: isSelected)
        }
    }

    func bind(item: MarketFilterViewItem) {
        iconImageView.image = UIImage(named: item.icon)
        titleLabel.text = item.title
        descriptionLabel.text = item.description
    }

    func bind(selected: Bool) {
        titleLabel.textColor = selected ? .themeDark : .themeLight

        descriptionLabel.isHidden = !selected
        contentView.backgroundColor = selected ? .themeJacob : .themeLawrence
    }

    static func size(item: MarketFilterViewItem, selected: Bool) -> CGSize {
        let titleWidth = item.title.size(containerWidth: .greatestFiniteMagnitude, font: FilterCard.titleFont).width
        var unselectedWidth = titleWidth + 2 * FilterCard.sideMargin
        unselectedWidth = max(unselectedWidth, 100)

        return CGSize(width: selected ? 212 : unselectedWidth, height: 94)
    }

}
