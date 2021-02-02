import UIKit
import ThemeKit
import SnapKit

class FilterCard: UICollectionViewCell {
    static let titleFont: UIFont = .subhead1
    static let sideMargin: CGFloat = .margin12

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    private var titleTopConstraint: Constraint?
    private var titleBottomConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.cornerRadius = .margin16

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(FilterCard.sideMargin)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(FilterCard.sideMargin)

            titleTopConstraint = maker.top.equalToSuperview().inset(FilterCard.sideMargin).constraint
            titleBottomConstraint = maker.bottom.equalToSuperview().inset(FilterCard.sideMargin).constraint
        }
        titleTopConstraint?.isActive = false
        titleBottomConstraint?.isActive = true

        titleLabel.font = FilterCard.titleFont
        titleLabel.textColor = .themeLight

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(FilterCard.sideMargin)
            maker.width.equalTo(188)
            maker.bottom.equalToSuperview().inset(FilterCard.sideMargin)
        }

        descriptionLabel.font = .caption
        descriptionLabel.numberOfLines = 0
        descriptionLabel.alpha = 0

        contentView.layoutIfNeeded()
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

    func bind(item: MarketFilterViewItem) {
        iconImageView.image = UIImage(named: item.icon)
        titleLabel.text = item.title
        descriptionLabel.text = item.description
    }

    func bind(selected: Bool) {
        titleLabel.textColor = selected ? .themeDark : .themeLight

        titleTopConstraint?.isActive = selected
        titleBottomConstraint?.isActive = !selected

        UIView.animateKeyframes(withDuration: .themeAnimationDuration, delay: 0) { [weak self] in
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                self?.contentView.layoutIfNeeded()
                self?.iconImageView.alpha = selected ?  0 : 1
            }

            let descriptionAnimationStartTime: TimeInterval = selected ? 0.6 : 0
            UIView.addKeyframe(withRelativeStartTime: descriptionAnimationStartTime, relativeDuration: 0.4) {
                self?.descriptionLabel.alpha = selected ? 1 : 0
            }
        }

        contentView.backgroundColor = selected ? .themeJacob : .themeLawrence
    }

    static func size(item: MarketFilterViewItem, selected: Bool) -> CGSize {
        let titleWidth = item.title.size(containerWidth: .greatestFiniteMagnitude, font: FilterCard.titleFont).width
        var unselectedWidth = titleWidth + 2 * FilterCard.sideMargin
        unselectedWidth = max(unselectedWidth, 100)

        return CGSize(width: selected ? 212 : unselectedWidth, height: 94)
    }

}
