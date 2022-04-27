import UIKit

class PerformanceContentCollectionViewCell: BasePerformanceCollectionViewCell {

    private let label = DiffLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        label.font = .caption
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(value: Decimal?, horizontalFirst: Bool, verticalFirst: Bool) {
        super.set(horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)

        label.set(value: value)
    }

}
