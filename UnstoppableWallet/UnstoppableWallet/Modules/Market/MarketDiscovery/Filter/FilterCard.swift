import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class FilterCard: UICollectionViewCell {
    private static let titleFont: UIFont = .subhead1
    private static let sideMargin: CGFloat = .margin12

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let blockchainBadgeView = BadgeView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.cornerRadius = .margin12
        contentView.borderWidth = .heightOneDp
        contentView.borderColor = .clear

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(FilterCard.sideMargin)
        }

        contentView.addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(14)
            maker.top.equalToSuperview().inset(FilterCard.sideMargin)
        }

        blockchainBadgeView.isHidden = true

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(FilterCard.sideMargin)
            maker.bottom.equalToSuperview().inset(FilterCard.sideMargin)
        }

        titleLabel.font = FilterCard.titleFont
        titleLabel.textColor = .themeOz

        contentView.backgroundColor = .themeLawrence
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            bind(selected: isSelected)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        iconImageView.image = nil
        titleLabel.text = nil
        blockchainBadgeView.text = nil
        blockchainBadgeView.isHidden = true
    }

    func bind(item: MarketDiscoveryFilterHeaderView.ViewItem) {
        iconImageView.setImage(withUrlString: item.iconUrl, placeholder: UIImage(named: item.iconPlaceholder))
        titleLabel.text = item.title
        if let badgeText = item.blockchainBadge {
            blockchainBadgeView.text = badgeText
            blockchainBadgeView.isHidden = false
        }
    }

    func bind(selected: Bool) {
        UIView.animate(withDuration: .themeAnimationDuration, delay: 0) {
            self.contentView.borderColor = selected ? .themeJacob : .clear
        }
    }

    static func size(item: MarketDiscoveryFilterHeaderView.ViewItem) -> CGSize {
        let titleWidth = item.title.size(containerWidth: .greatestFiniteMagnitude, font: FilterCard.titleFont).width
        let unselectedWidth = max(100, titleWidth + 2 * FilterCard.sideMargin)

        return CGSize(width: unselectedWidth, height: 94)
    }

}
