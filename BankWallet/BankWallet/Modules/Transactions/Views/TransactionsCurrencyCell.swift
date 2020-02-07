import UIKit
import SnapKit

class TransactionsCurrencyCell: UICollectionViewCell {
    private static let nameLabelFont = UIFont.subhead2
    private let roundedView = UIView()
    private let nameLabel = UILabel()
    private let verticalMargin: CGFloat = 6

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(roundedView)
        roundedView.addSubview(nameLabel)

        roundedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: verticalMargin, left: 0, bottom: verticalMargin, right: 0))
        }

        roundedView.layer.cornerRadius = 14             // (TransactionCurrenciesHeaderView.headerHeight - .margin2x * 2) / 2
        roundedView.layer.borderColor = UIColor.themeSteel20.cgColor
        roundedView.layer.borderWidth = .heightOneDp
        roundedView.clipsToBounds = true

        nameLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        nameLabel.font = TransactionsCurrencyCell.nameLabelFont
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override var isSelected: Bool {
        get {
            super.isSelected
        }
        set {
            super.isSelected = newValue
            bind(selected: newValue)
        }
    }

    func bind(title: String, selected: Bool) {
        nameLabel.text = title

        bind(selected: selected)
    }

    func bind(selected: Bool) {
        nameLabel.textColor = selected ? .themeDark : .themeOz
        roundedView.backgroundColor = selected ? .themeYellowD : .themeJeremy
    }

    static func size(for title: String) -> CGSize {
        let size = title.size(containerWidth: .greatestFiniteMagnitude, font: TransactionsCurrencyCell.nameLabelFont)
        let calculatedWidth = size.width + 2 * .margin8x
        return CGSize(width: max(calculatedWidth, 80), height: TransactionCurrenciesHeaderView.headerHeight)
    }

}
