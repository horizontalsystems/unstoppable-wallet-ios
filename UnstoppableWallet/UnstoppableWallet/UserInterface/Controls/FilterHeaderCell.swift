import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class FilterHeaderCell: UICollectionViewCell {
    private static let buttonStyle: ThemeButtonStyle = .tab

    private let button = ThemeButton()
    private let selectedView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.apply(style: FilterHeaderCell.buttonStyle)
        button.isUserInteractionEnabled = false

        contentView.addSubview(selectedView)
        selectedView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(2)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override var isSelected: Bool {
        didSet {
            bind(selected: isSelected)
        }
    }

    override var isHighlighted: Bool {
        didSet {
            bind(highlighted: isHighlighted)
        }
    }

    func bind(title: String?, selected: Bool) {
        button.setTitle(title, for: .normal)

        bind(selected: selected)
    }

    private func bind(selected: Bool) {
        button.isSelected = selected
        selectedView.backgroundColor = selected ? .themeJacob : .clear
    }

    private func bind(highlighted: Bool) {
        button.isHighlighted = highlighted
    }

}

extension FilterHeaderCell {

    static func size(for title: String) -> CGSize {
        CGSize(width: ThemeButton.size(containerWidth: .greatestFiniteMagnitude, text: title, style: buttonStyle).width, height: CGFloat.heightSingleLineCell)
    }

}
