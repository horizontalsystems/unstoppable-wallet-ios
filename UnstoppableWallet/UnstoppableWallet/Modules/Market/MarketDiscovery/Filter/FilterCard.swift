import UIKit
import ThemeKit
import SnapKit

class FilterCard: UICollectionViewCell {
    private static let titleFont: UIFont = .subhead1
    private static let sideMargin: CGFloat = .margin12

    private let iconImageView = UIImageView()
    private let titleLightLabel = UILabel()
    private let titleDarkLabel = UILabel()
    private let descriptionLabel = UILabel()

    private var titleLightTopConstraint: Constraint?
    private var titleLightBottomConstraint: Constraint?
    private var titleDarkTopConstraint: Constraint?
    private var titleDarkBottomConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.cornerRadius = .margin16

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(FilterCard.sideMargin)
        }

        contentView.addSubview(titleLightLabel)
        titleLightLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(FilterCard.sideMargin)

            titleLightTopConstraint = maker.top.equalToSuperview().inset(FilterCard.sideMargin).constraint
            titleLightBottomConstraint = maker.bottom.equalToSuperview().inset(FilterCard.sideMargin).constraint
        }
        titleLightTopConstraint?.isActive = false
        titleLightBottomConstraint?.isActive = true

        titleLightLabel.font = FilterCard.titleFont
        titleLightLabel.textColor = .themeOz

        contentView.addSubview(titleDarkLabel)
        titleDarkLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(FilterCard.sideMargin)

            titleDarkTopConstraint = maker.top.equalToSuperview().inset(FilterCard.sideMargin).constraint
            titleDarkBottomConstraint = maker.bottom.equalToSuperview().inset(FilterCard.sideMargin).constraint
        }
        titleDarkTopConstraint?.isActive = false
        titleDarkBottomConstraint?.isActive = true

        titleDarkLabel.alpha = 0
        titleDarkLabel.font = FilterCard.titleFont
        titleDarkLabel.textColor = .themeDark

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
        titleDarkLabel.text = nil
        descriptionLabel.text = nil
    }

    func bind(item: MarketFilterViewItem) {
        iconImageView.image = UIImage(named: item.icon)
        titleLightLabel.text = item.title
        titleDarkLabel.text = item.title
        descriptionLabel.text = item.description
    }

    func bind(selected: Bool) {
        titleLightTopConstraint?.isActive = selected
        titleLightBottomConstraint?.isActive = !selected
        titleDarkTopConstraint?.isActive = selected
        titleDarkBottomConstraint?.isActive = !selected

        UIView.animateKeyframes(withDuration: .themeAnimationDuration, delay: 0) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                self.contentView.layoutIfNeeded()
                self.titleLightLabel.alpha = selected ? 0 : 1
                self.titleDarkLabel.alpha = selected ? 1 : 0
            }

            UIView.addKeyframe(withRelativeStartTime: selected ? 0 : 0.5, relativeDuration: 0.5) {
                self.iconImageView.alpha = selected ?  0 : 1
            }

            UIView.addKeyframe(withRelativeStartTime: selected ? 0.6 : 0, relativeDuration: 0.4) {
                self.descriptionLabel.alpha = selected ? 1 : 0
            }

            self.contentView.backgroundColor = selected ? .themeYellowD : .themeLawrence
        }
    }

    static func size(item: MarketFilterViewItem, selected: Bool) -> CGSize {
        let titleWidth = item.title.size(containerWidth: .greatestFiniteMagnitude, font: FilterCard.titleFont).width
        let unselectedWidth = max(100, titleWidth + 2 * FilterCard.sideMargin)

        return CGSize(width: selected ? 212 : unselectedWidth, height: 84)
    }

}
