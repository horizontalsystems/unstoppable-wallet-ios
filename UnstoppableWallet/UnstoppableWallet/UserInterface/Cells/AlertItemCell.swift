import UIKit
import ThemeKit
import ComponentKit

class AlertItemCell: BaseThemeCell {
    private let button = UIButton()

    var onSelect: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topSeparatorView.snp.bottom)
            maker.bottom.equalTo(bottomSeparatorView.snp.top).priority(.high)
        }

        button.titleLabel?.font = .body
        button.setTitleColor(.themeJacob, for: .selected)
        button.setTitleColor(.themeJacob, for: [.highlighted, .selected])
        button.setTitleColor(.themeOz, for: .normal)
        button.setBackgroundColor(color: .themeLawrencePressed, forState: .highlighted)
        button.setBackgroundColor(color: .themeLawrencePressed, forState: [.highlighted, .selected])
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onSelect?()
    }

    var title: String? {
        get { button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
    }

    override var isSelected: Bool {
        get { super.isSelected }
        set {
            super.isSelected = newValue
            button.isSelected = newValue
        }
    }

}
