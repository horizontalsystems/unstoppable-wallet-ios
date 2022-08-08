import UIKit
import ThemeKit
import ComponentKit

class TraitCell: UICollectionViewCell {
    private static let horizontalPadding: CGFloat = .margin16
    private static let verticalPadding: CGFloat = 10
    private static let insidePadding: CGFloat = .margin6
    private static let valueFont: UIFont = .body
    private static let propertyFont: UIFont = .subhead2
    static let height: CGFloat = 60

    private let titleStackView = UIStackView()

    private let valueLabel = UILabel()
    private var percentBadge = BadgeView()
    private let typeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .themeLawrence
        contentView.cornerRadius = .cornerRadius12
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(titleStackView)
        titleStackView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(Self.horizontalPadding)
            maker.top.equalToSuperview().inset(Self.verticalPadding)
        }

        titleStackView.distribution = .equalSpacing
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.spacing = Self.insidePadding

        titleStackView.addArrangedSubview(valueLabel)

        valueLabel.font = Self.valueFont
        valueLabel.textColor = .themeLeah

        titleStackView.addArrangedSubview(percentBadge)
        percentBadge.set(style: .small)

        contentView.addSubview(typeLabel)
        typeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(Self.horizontalPadding)
            maker.top.equalTo(titleStackView.snp.bottom).offset(3)
        }

        typeLabel.font = Self.propertyFont
        typeLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: NftAssetOverviewViewModel.TraitViewItem) {
        valueLabel.text = viewItem.value
        typeLabel.text = viewItem.type
        percentBadge.text = viewItem.percent

        percentBadge.isHidden = viewItem.percent == nil
    }

    static func size(for viewItem: NftAssetOverviewViewModel.TraitViewItem, containerWidth: CGFloat) -> CGSize {
        let availableWidth = containerWidth - 2 * horizontalPadding

        let badgeWidth = (viewItem.percent.map { BadgeView.width(for: $0, change: nil, style: .small) }) ?? 0
        let availableValueWidth = availableWidth - (badgeWidth == 0 ? 0 : insidePadding) - badgeWidth
        let valueWidth = viewItem.value.size(containerWidth: availableValueWidth, font: valueFont).width
        let titleWidth = 2 * horizontalPadding + valueWidth + badgeWidth

        let propertyWidth = viewItem.type.size(containerWidth: availableWidth, font: propertyFont).width + 2 * horizontalPadding

        return CGSize(width: max(titleWidth, propertyWidth), height: height)
    }

    override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            contentView.backgroundColor = newValue ? .themeLawrencePressed : .themeLawrence
        }
    }

}
