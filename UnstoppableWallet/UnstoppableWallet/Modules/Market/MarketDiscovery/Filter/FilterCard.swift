import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class FilterCard: UICollectionViewCell {
    private static let titleFont: UIFont = .subhead1
    private static let sideMargin: CGFloat = .margin12
    private static let iconAndBadgeMargin: CGFloat = 14
    private static let iconWidth: CGFloat = 24

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let blockchainBadgeView = BadgeView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.cornerRadius = .margin12
        contentView.layer.cornerCurve = .continuous
        contentView.borderWidth = .heightOneDp
        contentView.borderColor = .clear

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(FilterCard.sideMargin)
            maker.size.equalTo(CGFloat.iconSize24)
        }

        contentView.addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.top.equalToSuperview().inset(FilterCard.sideMargin)
        }

        blockchainBadgeView.set(style: .small)
        blockchainBadgeView.isHidden = true

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(FilterCard.sideMargin)
            maker.bottom.equalToSuperview().inset(FilterCard.sideMargin)
        }

        titleLabel.font = FilterCard.titleFont
        titleLabel.textColor = .themeLeah

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

    func bind(item: MarketDiscoveryFilterHeaderView.ViewItem) {
        iconImageView.setImage(withUrlString: item.iconUrl, placeholder: UIImage(named: item.iconPlaceholder))
        titleLabel.text = item.title
        if let badgeText = item.blockchainBadge {
            blockchainBadgeView.text = badgeText
            blockchainBadgeView.isHidden = false
        } else {
            blockchainBadgeView.text = nil
            blockchainBadgeView.isHidden = true
        }
    }

    func bind(selected: Bool) {
        UIView.animate(withDuration: .themeAnimationDuration, delay: 0) {
            self.contentView.borderColor = selected ? .themeJacob : .clear
        }
    }

    static func size(item: MarketDiscoveryFilterHeaderView.ViewItem) -> CGSize {
        let titleWidth = item.title.size(containerWidth: .greatestFiniteMagnitude, font: FilterCard.titleFont).width
        var badgeWidth: CGFloat = 0
        if let badgeText = item.blockchainBadge {
            badgeWidth = BadgeView.width(for: badgeText, change: nil, style: .small)
            badgeWidth += iconAndBadgeMargin
        }
        let greaterWidth = max(titleWidth + 2 * FilterCard.sideMargin, iconWidth + badgeWidth + 2 * FilterCard.sideMargin)
        let width = max(100, greaterWidth)

        return CGSize(width: width, height: 94)
    }

}
