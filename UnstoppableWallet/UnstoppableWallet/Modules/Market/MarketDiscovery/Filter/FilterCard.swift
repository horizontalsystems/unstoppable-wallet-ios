import UIKit
import ThemeKit
import SnapKit

class FilterCard: UICollectionViewCell {
    private static let titleFont: UIFont = .subhead1
    private static let sideMargin: CGFloat = .margin12

    private let iconImageView = UIImageView()
    private let titleLightLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.cornerRadius = .margin12
        contentView.borderWidth = .heightOneDp
        contentView.borderColor = .clear

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(FilterCard.sideMargin)
        }

        contentView.addSubview(titleLightLabel)
        titleLightLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(FilterCard.sideMargin)
            maker.bottom.equalToSuperview().inset(FilterCard.sideMargin)
        }

        titleLightLabel.font = FilterCard.titleFont
        titleLightLabel.textColor = .themeOz

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(FilterCard.sideMargin)
            maker.width.equalTo(188)
            maker.bottom.equalToSuperview().inset(FilterCard.sideMargin)
        }

        descriptionLabel.font = .caption
        descriptionLabel.numberOfLines = 0
        descriptionLabel.alpha = 0
        descriptionLabel.textColor = .themeDark

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
        titleLightLabel.text = nil
        descriptionLabel.text = nil
    }

    func bind(item: MarketDiscoveryFilterHeaderView.ViewItem) {
        iconImageView.setImage(withUrlString: item.iconUrl, placeholder: UIImage(named: item.iconPlaceholder))
        titleLightLabel.text = item.title
        descriptionLabel.text = item.description
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
