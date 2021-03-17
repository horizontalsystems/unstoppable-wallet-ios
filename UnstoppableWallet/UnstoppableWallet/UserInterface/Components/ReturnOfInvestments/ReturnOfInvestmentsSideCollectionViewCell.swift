import UIKit

class ReturnOfInvestmentsSideCollectionViewCell: BaseReturnOfInvestmentsCollectionViewCell {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(cellType: ReturnOfInvestmentsTableViewCell.CellType, horizontalFirst: Bool, verticalFirst: Bool) {
        super.set(horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)

        label.font = cellType.font
        label.textColor = cellType.color
        contentView.backgroundColor = cellType.backgroundColor
    }

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

}
