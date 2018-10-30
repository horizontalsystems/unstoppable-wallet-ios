import UIKit
import SnapKit

class TransactionsCurrencyCell: UICollectionViewCell {

    var roundedView = UIView()
    var nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        roundedView.layer.cornerRadius = TransactionsFilterTheme.cornerRadius
        roundedView.layer.borderColor = TransactionsFilterTheme.borderColor.cgColor
        roundedView.layer.borderWidth = TransactionsFilterTheme.borderWidth
        roundedView.clipsToBounds = true
        contentView.addSubview(roundedView)
        roundedView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: TransactionsFilterTheme.nameVerticalMargin, left: 0, bottom: TransactionsFilterTheme.nameVerticalMargin, right: 0))
        }

        roundedView.addSubview(nameLabel)
        nameLabel.font = TransactionsFilterTheme.nameFont
        nameLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            super.isSelected = newValue
            bind(selected: newValue)
        }
    }

    func bind(transactionFilter: TransactionFilterItem, selected: Bool) {
        nameLabel.text = transactionFilter.name.localized.uppercased()

        bind(selected: selected)
    }

    func bind(selected: Bool) {
        nameLabel.textColor = selected ? TransactionsFilterTheme.selectedNameColor : TransactionsFilterTheme.deselectedNameColor
        roundedView.backgroundColor = selected ? TransactionsFilterTheme.selectedBackgroundColor : TransactionsFilterTheme.deselectedBackgroundColor
    }

    static func size(for filter: TransactionFilterItem) -> CGSize {
        let size = filter.name.size(containerWidth: .greatestFiniteMagnitude, font: TransactionsFilterTheme.nameFont)
        let calculatedWidth = size.width + 2 * TransactionsFilterTheme.nameHorizontalMargin
        return CGSize(width: max(calculatedWidth, TransactionsFilterTheme.nameMinWidth), height: TransactionsFilterTheme.filterHeaderHeight)
    }

}
