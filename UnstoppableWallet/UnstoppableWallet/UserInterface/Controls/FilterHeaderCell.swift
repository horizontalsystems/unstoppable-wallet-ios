import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class FilterHeaderCell: UICollectionViewCell {
    private let button = ThemeButton()
    private var buttonStyle: ThemeButtonStyle = .tab
    private let selectedView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

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
            bind(selected: isSelected, buttonStyle: buttonStyle)
        }
    }

    override var isHighlighted: Bool {
        didSet {
            bind(highlighted: isHighlighted)
        }
    }

    func bind(title: String?, selected: Bool, buttonStyle: ThemeButtonStyle) {
        self.buttonStyle = buttonStyle

        button.apply(style: buttonStyle)
        button.setTitle(title, for: .normal)

        bind(selected: selected, buttonStyle: buttonStyle)
    }

    private func bind(selected: Bool, buttonStyle: ThemeButtonStyle) {
        button.isSelected = selected
        selectedView.backgroundColor = selected && buttonStyle == .tab ? .themeJacob : .clear
    }

    private func bind(highlighted: Bool) {
        button.isHighlighted = highlighted
    }

}

extension FilterHeaderCell {

    static func height(buttonStyle: ThemeButtonStyle) -> CGFloat {
        buttonStyle == .tab ? CGFloat.heightSingleLineCell : 28
    }

    static func size(for title: String, buttonStyle: ThemeButtonStyle) -> CGSize {
        let height = height(buttonStyle: buttonStyle)
        return CGSize(width: ThemeButton.size(containerWidth: .greatestFiniteMagnitude, text: title, style: buttonStyle).width, height: height)
    }

}
