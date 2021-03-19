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

    func set(viewItem: CoinPageViewModel.ReturnOfInvestmentsViewItem, horizontalFirst: Bool, verticalFirst: Bool) {
        super.set(horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)

        label.font = viewItem.font
        label.textColor = viewItem.color
        contentView.backgroundColor = viewItem.backgroundColor
    }

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

}
