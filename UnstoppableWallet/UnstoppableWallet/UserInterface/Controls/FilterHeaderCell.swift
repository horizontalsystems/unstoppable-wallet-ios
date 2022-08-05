import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class FilterHeaderCell: UICollectionViewCell {
    private let button = SecondaryButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        button.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override var isSelected: Bool {
        didSet {
            button.isSelected = isSelected
        }
    }

    override var isHighlighted: Bool {
        didSet {
            button.isHighlighted = isHighlighted
        }
    }

    func bind(title: String?, selected: Bool, buttonStyle: SecondaryButton.Style) {
        button.set(style: buttonStyle)
        button.setTitle(title, for: .normal)
        button.isSelected = selected
    }

}

extension FilterHeaderCell {

    static func width(title: String) -> CGFloat {
        SecondaryButton.width(title: title)
    }

}
