import UIKit
import SnapKit

class ChartTypeCell: UICollectionViewCell {
    private static let nameLabelFont = UIFont.subhead2
    private let roundedView = UIView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(roundedView)
        roundedView.addSubview(nameLabel)

        roundedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        roundedView.layer.cornerRadius = .cornerRadius3x

        nameLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.center.equalToSuperview()
        }

        nameLabel.font = ChartTypeCell.nameLabelFont
        nameLabel.textAlignment = .center
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
        nameLabel.textColor = selected ? .themeJacob : .themeLeah
        roundedView.backgroundColor = selected ? .themeJeremy : .clear
    }

    static func size(for title: String) -> CGSize {
        let size = title.size(containerWidth: .greatestFiniteMagnitude, font: ChartTypeCell.nameLabelFont)
        let calculatedWidth = size.width + 2 * .margin4x
        return CGSize(width: min(calculatedWidth, 60), height: ChartTypeSelectView.headerHeight)
    }

}
