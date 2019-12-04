import UIKit
import SnapKit

class TransactionsCurrencyCell: UICollectionViewCell {
    private static let nameLabelFont = UIFont.appSubhead2
    private let roundedView = UIView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(roundedView)
        roundedView.addSubview(nameLabel)

        roundedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: CGFloat.margin2x, left: 0, bottom: CGFloat.margin2x, right: 0))
        }

        roundedView.layer.cornerRadius = 14             // (TransactionCurrenciesHeaderView.headerHeight - .margin2x * 2) / 2
        roundedView.layer.borderColor = UIColor.appSteel20.cgColor
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
        nameLabel.textColor = selected ? .appDark : .appOz
        roundedView.backgroundColor = selected ? .appJacob : .appJeremy
    }

    static func size(for title: String) -> CGSize {
        let size = title.size(containerWidth: .greatestFiniteMagnitude, font: TransactionsCurrencyCell.nameLabelFont)
        let calculatedWidth = size.width + 2 * .margin8x
        return CGSize(width: max(calculatedWidth, 88), height: TransactionCurrenciesHeaderView.headerHeight)
    }

}
